#let normalize-title(s) = {
  s
    .replace("output/", "")
    .replace(regex("[-,]+"), "・")
    .replace("_", " ")
    .replace(regex("[\u{1F1E6}-\u{1F1FF}]{2}"), "")
}
#let data = json("data.json")
#let htmls = data.filter(it => it.type == "directory").map(dir => label(normalize-title(dir.name)))
