#!/usr/bin/perl -w
#read a list of book provided by Soo Jin Team and grab the bookwriteup xml file to pack into a submission zip file for uploading into the backstage
#created by mike
#date 2018-07-03
#modified date 2022-06-21
use XML::LibXSLT;
use XML::LibXML;
use File::Copy;
use Business::ISBN;
use POSIX qw(strftime);
use POSIX;
use utf8;

# get rid of "Wide character in print ..." warning in STDOUT
binmode(STDOUT, ":utf8");

my ($line,$lines,$result,$log,$file,$raw,$output,$bookseries,$manifest,$tmp,$xmlfile);
my ($i,$x,$y,$z);
my (@data,@temp,@booklist,@urldata,@raw);
my (%bookset,%subjectlist,%bookfile,%individualfiles);
my $now_string = strftime "%Y%m%d%H%M%S", localtime;

if($ARGV[0] eq "")
{
  print "Please input the filename!\n";
  exit;
}
$file = $ARGV[0];
$i=0;
open (IN, "< $file") || die "Cannot open $file for reading";
while (<IN>) {
  $raw = $_;
  $raw =~ s/^\s+//;
  $raw =~ s/\s+$//;
  $raw =~ s/\n//;
  $raw =~ s/\r//;
  #$booklist[$i] = lc($raw);
  $booklist[$i] = $raw;
  print $booklist[$i]."\n";
  $i++;
}
close(IN);

$log = "Date: ".$now_string."\n";
$log .= "Book|Writeupfile|Note\n";
for($i=0;$i<@booklist;$i++)
{
  $xmlfile = "";
  @temp = split(/\./,$booklist[$i]);
  $temp[0] = lc($temp[0]);
  if(-e '/home/sgml/atypon/books/bookwriteup/standalonebook/'.$temp[0].'-writeup.xml')
  {
    $xmlfile='/home/sgml/atypon/books/bookwriteup/standalonebook/'.$temp[0].'-writeup.xml';
  }
  elsif(-e '/home/sgml/atypon/books/bookwriteup/bookseries/'.$temp[0].'-writeup.xml')
  {
    $xmlfile='/home/sgml/atypon/books/bookwriteup/bookseries/'.$temp[0].'-writeup.xml';
  }
  elsif(-e '/home/sgml/atypon/books/bookwriteup/bookset/'.$temp[0].'-writeup.xml')
  {
    $xmlfile='/home/sgml/atypon/books/bookwriteup/bookset/'.$temp[0].'-writeup.xml';
  }
  if($xmlfile eq "")
  {
    if(-e '/home/sgml/atypon/books/bookwriteup/bookset/'.$temp[0].'-setwriteup.xml')
	{
      $xmlfile='/home/sgml/atypon/books/bookwriteup/bookset/'.$temp[0].'-setwriteup.xml';  
	}
  }
  $log .= $temp[0]."|".$xmlfile;
  if($xmlfile eq ""){$log .= "|No xml file found!\n";next;}

  open (IN, "<:utf8","$xmlfile") || die "Cannot open $xmlfile for reading";
  @raw = <IN>;
  close(IN);
  $lines = "";
  foreach $line (@raw)
  { 
    $lines .= $line;
  }

  #to remove the $ sign from the xml file string
  $lines =~ s/[\$]//g;
  #$lines =~ s/[\[]//g;
  #$lines =~ s/[\]]//g;
  $lines =~ s/<!\-\- <Key Features>.*<\/Key Features> \-\->//g;
  $lines =~ s/<!-- <Key Features>.*<\/Key Features> -->//g;
  if($lines =~ /<!-- <Key Features>(.*?)<\/Key Features> -->/s)
  {
    $tmp = $1;
    $tmp =~ s/\?/\\?/g;
    $tmp =~ s/\:/\\:/g;
    $tmp =~ s/\(/\\(/g;
    $tmp =~ s/\)/\\)/g;
    $tmp =~ s/[\[]/\\[/g;
    $tmp =~ s/[\]]/\\]/g;
    #print "$tmp\n";
    $lines =~ s/<!-- <Key Features>//g;
    $lines =~ s/<\/Key Features> -->//g;
    $lines =~ s/$tmp//g;
    #print "$lines\n";
    #exit;
  }

  $lines =~ s/<!-- <Remarks>*\(*\)*<\/Remarks> -->//g;
  if($lines =~ /<!-- <Remarks>(.*?)<\/Remarks> -->/s)
  {
    $tmp = $1;
	  $tmp =~ s/\?/\\?/g;
    $tmp =~ s/\:/\\:/g;
    $tmp =~ s/\(/\\(/g;
    $tmp =~ s/\)/\\)/g;
    $lines =~ s/<!-- <Remarks>//g;
    $lines =~ s/<\/Remarks> -->//g;
    $lines =~ s/$tmp//g;
  }
  #print "$lines\n";
  #exit;

  $bookseries = "";
  $manifest = '<?xml version="1.0" encoding="utf-8"?>'."\n".'<!DOCTYPE submission PUBLIC "-//Atypon//DTD Literatum Content Submission Manifest DTD v4.2 20140519//EN" "manifest.4.2.dtd">'."\n";
  $manifest .= '<submission dtd-version="4.2" group-doi="10.5555/default-do-group" submission-type="full">'."\n";
  $manifest .= '<processing-instructions>'."\n";
  $manifest .= '<make-live on-condition="no-fatals"/>'."\n";
  $manifest .= '</processing-instructions>'."\n";
  $manifest .= '</submission>';

  open (MYFILE, '> manifest.xml');
  print MYFILE $manifest;
  close (MYFILE);
  
  if($xmlfile =~ m/setwriteup/)
  {
    if(! -d "./do.".$temp[0]."-setwriteup")
    {
      `mkdir do.$temp[0]-setwriteup`;
	  `mkdir do.$temp[0]-setwriteup/meta`;
    }
    open (MYFILE, ">:utf8", "do.$temp[0]-setwriteup.xml");
    print MYFILE $lines;
    close (MYFILE);
	`mv do.$temp[0]-setwriteup.xml ./do.$temp[0]-setwriteup/meta`;
	$tmp = 'digital-objects_do.'.$temp[0].'-setwriteup_'.$now_string.'.zip';
	`zip -r $tmp ./do.$temp[0]-setwriteup manifest.xml;`;
  }
  else
  {
    if(! -d "./do.".$temp[0]."-writeup")
    {
      `mkdir do.$temp[0]-writeup`;
	  `mkdir do.$temp[0]-writeup/meta`;
    }
    open (MYFILE, ">:utf8", "do.$temp[0]-writeup.xml");
    print MYFILE $lines;
    close (MYFILE);
	`mv do.$temp[0]-writeup.xml ./do.$temp[0]-writeup/meta`;
	$tmp = 'digital-objects_do.'.$temp[0].'-writeup_'.$now_string.'.zip';
	`zip -r $tmp ./do.$temp[0]-writeup manifest.xml;`;
  }
  unlink('manifest.xml');
  if($xmlfile =~ m/setwriteup/){`rm -r ./do.$temp[0]-setwriteup`;}
  else{`rm -r ./do.$temp[0]-writeup`;}
  $log .= "|Done\n";
}

#write log file
open (MYFILE, '> generatebookwriteupfile.log');
print MYFILE $log;
close (MYFILE);
