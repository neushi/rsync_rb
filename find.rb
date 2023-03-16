#!/bin/sh
exec ruby -x "$0" "$@"
# wikipedia シバン (Unix)を参考に #!/usr/bin/env rubyを修正
# 親プロセスが独自にPATHを設定していた場合、想定外の動作をする可能性がある、らしい。
# ruby -x[directory]
# メッセージ中のスクリプトを取り出して実行します。スクリプトを 読み込む時に、`#!'で始まり, "ruby"という文字列を含む行までを 読み飛ばします。スクリプトの終りはEOF(ファイル の終り), ^D(コントロールD), ^Z(コ ントロールZ)または予約語__END__で指定されます。
# ディレクトリ名を指定すると、スクリプト実行前に指定されたディレクトリに移動します。

#!ruby
# vim:set fileencoding=utf-8:

require "open3"
require "find"

s = '/Users/dm/Desktop/git/rsync_rb'
o = '/Users/dm/Desktop/コピー/消して良い'

newer_files = []
Find.find(s) { | file | 
  source_file = file
  deleted_file = file.sub(s,o)
  p (file.sub(s + '/',""))  if  ( File.new(source_file).mtime <= File.new(deleted_file).mtime )
}

