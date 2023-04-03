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
  Backup = "BACKUP_hokadetsukawanaiDirName".freeze
  Source1 = "/Volumes/s1/".freeze
  Destination1 = "/Volumes/s1_bak/backup_rsync".freeze
#  Source2 = "s2".freeze
#  Destination2 = "d2".freeze
end
Freezer.freeze

def backup(source, destination)
  if (`rsync --version` !~ /rsync  version 3.2.3/) then
    printf("%s : rsyncのversion が変わりました!\n", $0)
    exit
  end

  source.freeze
  destination.freeze
  now = Time.now.strftime("%Y%m%d%H%M%S")
  backup_dirs = %Q!#{Freezer::Backup}!
  backup_dir_now = %Q!#{backup_dirs}/#{File.basename(source)}.#{now}.obsolete!
  log_file_now = "#{File.basename(source)}.#{now}.log"
  cmd1 = ""
  ["rsync",
  #   "--dry-run",
    # "-c",    # 異同判別に、日付とサイズだけでなく、チェックサムも使用
     "-v",
     "--delete",
     "-aH",
      "-NA", # Ver.3.1.1
    "--fileflags", # Ver.3.1.1
     "--xattrs",              # Ver.3.1.1では、finderコメントを変えても反映されない事がある(.DS_Storeはコピーされているのに)
     "--force-change", # Ver.3.1.1
     "--exclude='.fseventsd'",
     "--exclude='.Spotlight-V100'",
     "--exclude='.DocumentRevisions-V100'",
     "--exclude='.TemporaryItems'",
   #  "--exclude='.Trash'",
     "--exclude='.Trashes'",
     %Q!--exclude='#{backup_dirs}'!,      
     %Q!--backup-dir='#{backup_dir_now}'!,
     %Q!--exclude='#{log_file_now}'!,
     %Q!--log-file='#{destination}/#{log_file_now}'!,
    # "--log-file-format='%o %h [%a] %m (%u) %f %l'",
   #  "--update",              # skip files that are newer on the receiver
     "--backup",
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
     %Q!'#{source}'!,
     %Q!'#{destination}'!,
  ].each {|i| cmd1 << (i + ' ') }
  # 変化しても情報が減らないので付けないオプション　--hfs-compression --protect-decmpfs

  printf("\ncmd1 : %s\n\n", cmd1)
  stdin, stdout, stderr, wait_thr = Open3.popen3(cmd1)
  stdin.close    # または close_write
  Thread.fork{
    stderr.each do |l|
      print l
    end
  }
  stdout.each_line("\r") do |line|
      print  line
  end
  newerFiles = []
  Find.find( destination + "/" + backup_dir_now) { | file |
    next if (file == (destination + "/" + backup_dir_now) )
    next if (file =~ %r!#{destination}/#{backup_dir_now}/#{File.basename(source)}.[0-9]{14}.log!)
    next if File.directory?(file) 

    deleted_file = file
    updated_file = file.sub(destination + "/" + backup_dir_now , source.chop)
    next unless File.exist?(updated_file)
   #   p deleted_file
    #  p updated_file 
    newerFiles.push(file.sub(destination + "/" + backup_dir_now + "/", ""))  if  ( File.new(updated_file).mtime < File.new(deleted_file).mtime )
  }

  if 0 < newerFiles.size then
    p "== 新しいファイルが削除されます ================================"
    newerFiles.each do |line|
      p line
    end
    p "== 新しいファイルが削除されます ================================"
  end
  printf("異常終了しました (%s)", wait_thr.value.exitstatus) if wait_thr.value.exitstatus != 0

end

p "備忘 "+Freezer::Source1+" ＝＞ "+Freezer::Destination1
backup(Freezer::Source1, Freezer::Destination1)
# p "備忘 "+Freezer::Source2+" ＝＞ "+Freezer::Destination2
# Backup(Freezer::Source2, Freezer::Destination2)
__END__

# Backup Bouncerで検証
