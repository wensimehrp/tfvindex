// @typstyle off
#let map = (
  // monographs
  ア: "a",   イ: "i",   ウ: "u",   エ: "e",   オ: "o",
  カ: "ka",  キ: "ki",  ク: "ku",  ケ: "ke",  コ: "ko",
  サ: "sa",  シ: "shi", ス: "su",  セ: "se",  ソ: "so",
  タ: "ta",  チ: "chi", ツ: "tsu", テ: "te",  ト: "to",
  ナ: "na",  ニ: "ni",  ヌ: "nu",  ネ: "ne",  ノ: "no",
  ハ: "ha",  ヒ: "hi",  フ: "fu",  ヘ: "he",  ホ: "ho",
  マ: "ma",  ミ: "mi",  ム: "mu",  メ: "me",  モ: "mo",
  ヤ: "ya",             ユ: "yu",             ヨ: "yo",
  ラ: "ra",  リ: "ri",  ル: "ru",  レ: "re",  ロ: "ro",
  ワ: "wa",                                   ヲ: "wo",
  ン: "n",
  // diacritics
  ガ: "ga",  ギ: "gi",  グ: "gu",  ゲ: "ge",  ゴ: "go",
  ザ: "za",  ジ: "ji",  ズ: "zu",  ゼ: "ze",  ゾ: "zo",
  ダ: "da",  ヂ: "ji",  ヅ: "zu",  デ: "de",  ド: "do",
  バ: "ba",  ビ: "bi",  ブ: "bu",  ベ: "be",  ボ: "bo",
  パ: "pa",  ピ: "pi",  プ: "pu",  ペ: "pe",  ポ: "po",
  // digraphs
  キャ: "kya", キュ: "kyu", キョ: "kyo",
  シャ: "sha", シュ: "shu", ショ: "sho",
  チャ: "cha", チュ: "chu", チョ: "cho",
  ニャ: "nya", ニュ: "nyu", ニョ: "nyo",
  ヒャ: "hya", ヒュ: "hyu", ヒョ: "hyo",
  ミャ: "mya", ミュ: "myu", ミョ: "myo",
  リャ: "rya", リュ: "ryu", リョ: "ryo",
  ギャ: "gya", ギュ: "gyu", ギョ: "gyo",
  ジャ: "ja",  ジュ: "ju",  ジョ: "jo",
  ビャ: "bya", ビュ: "byu", ビョ: "byo",
  ピャ: "pya", ピュ: "pyu", ピョ: "pyo",
  // special and extended
  ッ: none,
  ー: none,
  ファ: "fa",  フィ: "fi",  フェ: "fe",  フォ: "fo",
  ヴァ: "va",  ヴィ: "vi",  ヴ: "vu",   ヴェ: "ve",  ヴォ: "vo",
  チェ: "che", シェ: "she", ジェ: "je",  ティ: "ti",  ディ: "di",
  デュ: "dyu", トゥ: "tu",  ドゥ: "du",  ウィ: "wi",  ウェ: "we",  ウォ: "wo"
)

/// Romanize the input Katakana string.
#let romanize-katakana(input) = {
  let clusters = input.clusters()
  let result = ""
  let i = 0

  while i < clusters.len() {
    // 2 char sequence
    if i + 1 < clusters.len() {
      let pair = clusters.at(i) + clusters.at(i + 1)
      if pair in map {
        result += map.at(pair)
        i += 2
        continue
      }
    }

    let current = clusters.at(i)

    // ッ
    if current == "ッ" {
      if i + 1 < clusters.len() {
        let next_char = clusters.at(i + 1)
        // check digraph
        if i + 2 < clusters.len() {
          let next_pair = next_char + clusters.at(i + 2)
          if next_pair in map {
            result += map.at(next_pair).clusters().at(0)
            i += 1
            continue
          }
        }
        // fallback
        if next_char in map {
          result += map.at(next_char).clusters().at(0)
        }
      }
      i += 1
      continue
    }

    // ー repeats previous vowel
    if current == "ー" {
      if result.len() > 0 {
        result += result.clusters().last()
      }
      i += 1
      continue
    }

    // standard lookup
    if current in map {
      result += map.at(current)
    } else {
      // keep non-katakana as-is
      result += current
    }

    i += 1
  }

  return result
}

#let romanize(input) = {
  import "@preview/auto-jrubby:0.3.4": tokenize
  tokenize(input)
    .map(it => {
      let last = it.details.last()
      if last == "UNK" {
        // Unknown. Is not Japanese
        it.surface
      } else {
        last
      }
    })
    .map(romanize-katakana)
    .join(" ", default: "")
}
