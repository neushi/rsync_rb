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

module Freezer
  # Source = ARGV[0]          #
  # Destination = ARGV[1]     #
  Source1 = "s1".freeze
  Destination1 = "d1".freeze
  Source2 = "s2".freeze
  Destination2 = "d2".freeze
end
Freezer.freeze

def Backup(source, destination)
  if (`rsync --version` !~ /rsync  version 2.6.9/) then
    printf("%s : rsyncのversion が変わりました!\n", $0)
    exit
  end

  source.freeze
  destination.freeze
  now = Time.now.strftime("%Y%m%d%H%M%S")
  cmd1 = ""
  ["rsync",
     "--dry-run",
     "-v",
     "--delete",
     "-aH",
     # "-NA", # Ver.3.1.1
     # "--fileflags", # Ver.3.1.1
  #   "--xattrs",              # Ver.3.1.1では、finderコメントを変えても反映されない事がある(.DS_Storeはコピーされているのに)
     # "--force-change", # Ver.3.1.1
     "--exclude='.fseventsd'",
     "--exclude='.Spotlight-V100'",
     "--exclude='.DocumentRevisions-V100'",
     "--exclude='.Trash'",
     %Q!--exclude='#{File.basename(source)}.obsolete*'!,
     %Q!--exclude='#{File.basename(source)}.*.log'!,
     "--update",              # skip files that are newer on the receiver
     "--backup",
     %Q!--backup-dir='#{File.basename(source)}.obsolete#{now}'!,
     "--progress",
     "--human-readable",
     "-i",                    # output a change-summary for all updates
     "-stats",
     # "-vv",
     # "--info=backup", # Ver.3.1.1
     # "--info=copy", # Ver.3.1.1
     # "--info=del", # Ver.3.1.1
     # "--info=misc2", # Ver.3.1.1
     # "--info=name1", # Ver.3.1.1
     # "--info=progress2", # Ver.3.1.1
     # "--info=remove",  # Ver.3.1.1
     # "--info=skip", # Ver.3.1.1
     # "--info=stats3", # Ver.3.1.1
     # "--info=symsafe", # Ver.3.1.1
     %Q!--log-file='#{destination}/#{File.basename(source)}.#{now}.log'!,
    # "--log-file-format='%o %h [%a] %m (%u) %f %l'",
     %Q!'#{source}'!,
     %Q!'#{destination}'!,
  ].each {|i| cmd1 << (i + ' ') }
  # 変化しても情報が減らないので付けないオプション　--hfs-compression --protect-decmpfs

  printf("\ncmd1 : %s\n\n", cmd1)
  stdin, stdout, stderr, wait_thr = Open3.popen3(cmd1)
  stdin.close    # または close_write
  Thread.fork{
    stderr.each do |l|
      print ("stderr: " + l)
    end
  }
  newerFiles = []
  stdout.each_line("\r", true ) do |line|
    print ("stdout: " + line)
    line.each_line("\n") do |ln|
      newerFiles.push ln if ln =~ /newer/
    end
  end
  p "=================================="
  newerFiles.each do |line|
    print line
  end
  p "=================================="
  printf("異常終了しました (%s)", wait_thr.value.exitstatus) if wait_thr.value.exitstatus != 0
end

newerFiles = []
Find.find(root) { | file | 
   sorce_file = 
   deleted_file = 
   newerFiles.push deleted_file if deleted_file is newer  
}


p "備忘 "+Freezer::Source1+" ＝＞ "+Freezer::Destination1
p "備忘 "+Freezer::Source2+" ＝＞ "+Freezer::Destination2
Backup(Freezer::Source1, Freezer::Destination1)
Backup(Freezer::Source2, Freezer::Destination2)

__END__

# Backup Bouncerで検証
