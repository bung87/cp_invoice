import std/[os, asyncdispatch, osproc, uri, sets, hashes]
import clipboard
import regex
import strutils
import sequtils
import filetype

proc main() {.async.} =
  let cur = getCurrentDir()
  var csets: HashSet[Hash]
  var s: string
  var sum: float
  var nums: seq[float]
  while true:
    await sleepAsync(1000)
    if clipboardWithName(CboardGeneral).readString(s):
      s.stripLineEnd
      if s.len > 0:
        let h = hash(s)
        if not csets.contains(h):
          csets.incl hash(s)
          var matches = newSeq[string]()
          var links = newSeq[string]()
          for m in findAll(s, re"\d+\.\d+"):
            matches.add s[m.boundaries]
          for m in findAll(s, re"https?://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]"):
            links.add s[m.boundaries]
          if matches.len > 0:
            nums = matches.mapIt(parseFloat(it))
            sum = foldl(nums, a + b)
          if links.len > 0 and matches.len > 0:
            echo "found $1 numbers, $2 links" % [$nums.len, $links.len]
            echo "sum $1" % [$sum]
            echo links
            var name: string
            var uri: Uri
            var path: string
            for link in links:
              uri = parseUri link
              path = uri.path
              name = extractFilename(path)
              let (headers, code) = execCmdEx("curl -sI $1" % [link])
              if headers.len > 0:
                var m: RegexMatch
                if find(headers, re"(?i)filename=(.*)", m):
                  name = m.groupFirstCapture(0, headers)
                  echo "remote name: $1" % [name]
              doAssert isValidFilename(name)
              let (output, exitCode) = execCmdEx("curl -o $1 $2" % [cur/name, link])
              doAssert exitCode == 0, output
              let kind = matchFile(cur / name)
              echo "safe extension: $1" % [kind.extension]
              if kind.extension.len > 0:
                let newName = name.changeFileExt(kind.extension)
                if newName != name:
                  moveFile(cur / name, cur / newName)
    else:
      discard

when isMainModule:
  waitFor main()
