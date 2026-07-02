#!/usr/bin/env python3.14
# /// script
# requires-python = ">=3.14"
# dependencies = [
#      "beautifulsoup4",
#      "httpx",
#      "tqdm",
#      "html5lib",
# ]
# ///
# This scraper uses html5lib because the HTML from the site is MALFORMED
# THE STANDARD LIBRARY html.parse WILL NOT WORK

import asyncio
import re
from pathlib import Path
from urllib.parse import urljoin, urlparse

import httpx
from bs4 import BeautifulSoup
from tqdm.asyncio import tqdm

# Global configuration limits
MAX_CONCURRENT_PRIMARY_WORKERS = 10
MAX_CONCURRENT_SECONDARY_WORKERS = 25
# Limit connections to prevent abusing the host
LIMITS = httpx.Limits(max_keepalive_connections=10, max_connections=50)

BASE_URL = "http://trainfrontview.net/"
INDEX_URL = "http://trainfrontview.net/sozai.htm"


def sanitize_path(path):
    return (
        path.strip()
        .replace("/", "-")
        .replace("\\", "-")
        .replace(" ", "_")
        .replace("*", "")
        .replace("<", "")
        .replace(">", "")
        .replace("|", "")
        .replace("?", "")
    )


# regular expression to match an integer right before the file extension
# e.g., matching the '1' in 'sozai-1.htm' or 'page2.html'
PAGINATION_REGEX = re.compile(r"(\d+)(\.[a-zA-Z0-9]+)$")


async def primary_worker(
    worker_id, primary_queue, secondary_queue, client, pbar, s_pbar
):
    while True:
        (output_dir, base_url) = await primary_queue.get()
        current_url = base_url

        try:
            # Check if the URL filename ends with a digit
            match = PAGINATION_REGEX.search(urlparse(current_url).path)
            is_paginated = match is not None

            if is_paginated:
                current_digit = int(match.group(1))
                file_extension = match.group(2)
                # Base string template to reconstruct URLs: "http://.../sozai-{}.htm"
                url_template = current_url.replace(
                    f"{current_digit}{file_extension}", f"{{}}{file_extension}"
                )

            # Nested loop to handle potential sequential pages
            while True:
                try:
                    output_dir.mkdir(exist_ok=True)
                    response = await client.get(current_url, timeout=10.0)

                    # Break the sequence if we hit a 404 or any other dead end
                    if response.status_code != 200:
                        break

                    soup = BeautifulSoup(response.content, "html5lib")
                    for li in soup.select("div#box-icons li"):
                        text_segments = [
                            seg.strip() for seg in li.stripped_strings if seg.strip()
                        ]
                        folder_name = "++".join(text_segments)
                        folder_name = sanitize_path(folder_name)
                        if not folder_name:
                            folder_name = "unknown_asset"
                        secondary_output_dir = output_dir / folder_name
                        secondary_output_dir.mkdir(exist_ok=True)

                        for src in (
                            img.get("src") for img in li.select("img") if img.get("src")
                        ):
                            img_url = urljoin(BASE_URL, src)
                            await secondary_queue.put((secondary_output_dir, img_url))
                            s_pbar.total += 1
                    s_pbar.refresh()

                except httpx.HTTPStatusError as e:
                    if e.response.status_code == 404:
                        break

                # If the URL wasn't paginated to begin with, finish after one execution
                if not is_paginated:
                    break

                current_digit += 1
                current_url = url_template.format(current_digit)

        except Exception as e:
            pbar.write(f"Error processing primary {current_url}: {e}")
        finally:
            primary_queue.task_done()
            pbar.update(1)


async def secondary_worker(worker_id, secondary_queue, client, pbar):
    while True:
        (output_dir, url) = await secondary_queue.get()
        try:
            filename = Path(url).name
            file_path = output_dir / filename
            source_path = output_dir / f"{filename}.source"

            response = await client.get(url, timeout=10.0)
            if response.status_code == 200:
                file_path.write_bytes(response.content)
            source_path.write_text(url, encoding="utf-8")

        except Exception as e:
            pbar.write(f"Error processing secondary {url}: {e}")
        finally:
            secondary_queue.task_done()
            pbar.update(1)


async def main():
    output_dir = Path("output")
    output_dir.mkdir(exist_ok=True)

    async with httpx.AsyncClient(limits=LIMITS) as client:
        response = await client.get(INDEX_URL)
        soup = BeautifulSoup(response.content, "html5lib")

        primary_queue = asyncio.Queue()
        secondary_queue = asyncio.Queue()

        links_to_seed = []
        for div in soup.select("div.ico"):
            base_text = "".join(div.find_all(string=True, recursive=False)).strip()
            for link in div.select("a"):
                href = link.get("href")
                dir = base_text + link.text
                dir = sanitize_path(dir)
                if href:
                    url = urljoin(BASE_URL, href)
                    links_to_seed.append((output_dir / dir, url))

        for dir, link in links_to_seed:
            await primary_queue.put((dir, link))

        p_pbar = tqdm(total=len(links_to_seed), desc="Primary Indexes", position=0)
        s_pbar = tqdm(total=0, desc="Downloaded IMGs", position=1, unit="img")

        p_workers = [
            asyncio.create_task(
                primary_worker(
                    i,
                    primary_queue,
                    secondary_queue,
                    client,
                    p_pbar,
                    s_pbar,
                )
            )
            for i in range(MAX_CONCURRENT_PRIMARY_WORKERS)
        ]

        s_workers = [
            asyncio.create_task(secondary_worker(i, secondary_queue, client, s_pbar))
            for i in range(MAX_CONCURRENT_SECONDARY_WORKERS)
        ]

        await primary_queue.join()
        p_pbar.close()

        await secondary_queue.join()
        s_pbar.close()

        for w in p_workers + s_workers:
            w.cancel()


if __name__ == "__main__":
    asyncio.run(main())
