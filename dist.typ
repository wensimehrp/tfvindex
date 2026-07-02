#!/usr/bin/env -S typst compile --features bundle,html --format bundle
#import "@preview/typhoon:0.1.2": _plugin
#let root = sys.inputs.at("root", default: "")
#let document(root: root, path, ..args) = std.document(root + path, ..args)

#let tailwind-classes = state("tailwind-classes", ())
#show html.elem: elem => {
  let classes = elem.fields().attrs.at("class", default: ())
  let classes = if type(classes) == str {
    classes.split(" ")
  } else {
    classes
  }
  tailwind-classes.update(it => {
    (it + classes).sorted().dedup()
  })
  elem
}

#context {
  asset(
    root + "/styles.css",
    ```css
    @import url('https://fonts.googleapis.com/css2?family=M+PLUS+U:wght@100..900&display=swap');

    :root {
      text-autospace: normal;
      text-spacing-trim: trim-start;
    }

    ```.text
      + str(_plugin.generate(
        bytes(
          tailwind-classes.final().join(" ") + "",
        ),
        cbor.encode((
          preflight: (
            full: (
              font_family_sans: "M PLUS U",
            ),
          ),
        )),
      )).replace("M PLUS U", "\"M PLUS U\""),
  )
}

#let basic(c, page-title: none) = {
  import html: *
  html(lang: "ja", {
    head({
      meta(charset: "utf-8")
      meta(name: "viewport", content: "width=device-width, initial-scale=1")
      link(rel: "stylesheet", href: "/" + root + "styles.css")
      title(page-title)
    })
    body(class: "bg-stone-100 dark:bg-zinc-800", {
      article(
        class: (
          "prose",
          "prose-headings:font-[M_PLUS_U]",
          "dark:prose-invert",
          "max-w-7xl",
          "mx-auto",
          "px-5",
          "my-20",
          "prose-pre:bg-zinc-900",
          "prose-pre:rounded-none",
        ),
        c,
      )
      footer(class: "p-5 prose")[
        Copyright #sym.copyright 2001--2026 #std.link("http://trainfrontview.net/")[Train Front View curoka], All Rights
        Reserved. \ Arranged by Jeremy Gao \@ paiagram.com
      ]
    })
  })
}

#let data = json("data.json")
#for dir in data.filter(it => it.type == "directory") {
  let contents = dir
    .contents
    .filter(it => it.type == "directory")
    .map(dir => html.div(
      class: "p-2 border border-gray-500/30 flex-auto",
      {
        let (heading-text, ..rest) = dir
          .name
          .split("/")
          .last()
          .replace("*", "")
          .replace("★", "")
          .replace("_", " ")
          .split("++")
        html.div(class: "[&>h2]:my-0 px-1 min-h-20", {
          let displayed-text = heading-text.replace(regex("[-,]+"), "・").replace("(", "（").replace(")", "）")
          html.h2(id: displayed-text, {
            displayed-text
            html.a(
              class: "text-blue-500 ml-2 no-underline opacity-0 hover:opacity-100",
              href: "#" + displayed-text,
              "↗",
            )
          })
          rest.join[, ]
        })
        html.div(
          class: "flex flex-wrap gap-2 [&>img]:flex-auto [&>img]:m-0 [&>img]:w-20 [&>img]:h-24 [&>img]:object-contain [image-rendering:pixelated]",
          for img in dir.contents.filter(file => (
            file.type == "file" and file.name.ends-with(".png")
          )) {
            image(img.name)
          },
        )
      },
    ))
  [#document(
      dir.name.replace("output/", "") + ".html",
      basic(html.div(class: "flex flex-wrap gap-3", contents.join(
        parbreak(),
      ))),
    ) #label(dir.name)]
}

#let htmls = data.filter(it => it.type == "directory").map(dir => label(dir.name))
#document("index.html", basic(html.div(
  class: "flex flex-wrap gap-3 *:flex-auto *:text-center *:border *:border-gray-500/30 *:px-4 *:py-1.5 *:no-underline *:hover:underline",
  htmls.map(it => link(it, str(it).replace("output/", "").replace(regex("[-,]+"), "・").replace("_", " "))).join(),
)))
