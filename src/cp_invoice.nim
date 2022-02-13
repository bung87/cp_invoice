import std/[os, asyncdispatch, httpclient, asyncfutures, sets, hashes]
import clipboard
import regex
import strutils
import sequtils
# import filetype

proc main() {.async.} =
  var client = newAsyncHttpClient()
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
          for m in findAll(s, re"(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]"):
            links.add s[m.boundaries]
          if matches.len > 0:
            nums = matches.mapIt(parseFloat(it))
            sum = foldl(nums, a + b)
          if links.len > 0 and matches.len > 0:
            echo "found $1 numbers, $2 links" % [$nums.len, $links.len]
            echo "sum $1" % [$sum]
            echo links
            await all links.mapIt(client.downloadFile(it, cur / extractFilename(it) ))
    else:
      discard

when isMainModule:
  waitFor main()