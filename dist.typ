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

#let box-classes = " bg-transparent dark:bg-zinc-700 border border-gray-500/30 dark:border-transparent "

#let basic(c, page-title: none, header-content: none) = {
  import html: *
  html(lang: "ja", {
    head({
      meta(charset: "utf-8")
      meta(name: "viewport", content: "width=device-width, initial-scale=1")
      link(rel: "stylesheet", href: "/" + root + "styles.css")
      title(page-title)
    })
    body(class: "bg-stone-100 dark:bg-zinc-800", {
      header-content
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
      footer(class: "p-5 prose dark:prose-invert")[
        Copyright #sym.copyright 2001--2026 #std.link("http://trainfrontview.net/")[Train Front View curoka], All Rights
        Reserved. \ Arranged by Jeremy Gao \@ paiagram.com
      ]
    })
  })
}

#let normalize-title(s) = {
  s.replace(regex("[-,]+"), "・").replace("_", " ")
}

#let data = json("data.json")
#for dir in data.filter(it => it.type == "directory") {
  let contents = dir
    .contents
    .filter(it => it.type == "directory")
    .map(dir => html.div(
      class: box-classes + "flex-auto p-2 print:break-inside-avoid",
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
      basic({
        title(normalize-title(dir.name.replace("output/", "")))
        html.div(class: "flex flex-wrap gap-3", contents.join(
          parbreak(),
        ))
      }),
    ) #label(dir.name)]
}

#let htmls = data.filter(it => it.type == "directory").map(dir => label(dir.name))
#document("index.html", basic({
  [
    #title[TFVIndex]
    A reorganization of icons at http://trainfrontview.net. \
    Please refer to http://trainfrontview.net/iconinfo.htm for the usage policy.

    TFVIndexは、http://trainfrontview.net のアイコンを再編成したものです。\
    利用規約については、http://trainfrontview.net/iconinfo.htm をご参照ください。

    *Use the `Ctrl+P` shortcut to print the page to a PDF file.*

    == Icons
  ]
  html.div(
    class: box-classes.split(regex("\s+")).map(cls => "*:" + cls).join(" ")
      + " flex flex-wrap gap-3 *:flex-auto *:text-center *:px-4 *:py-1.5 *:no-underline *:hover:underline",
    htmls.map(it => link(it, normalize-title(str(it).replace("output/", "")))).join(),
  )
})) <home>
