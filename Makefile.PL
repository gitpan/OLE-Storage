#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile (
   #
   # Editable:
   "INSTALLSCRIPT" => "/usr/local/bin/",

   #
   # Do not edit this:
   "NAME"      => "OLE::Storage",
   "VERSION"   => "0.381",
   "dist"      => {
      "COMPRESS" => "gzip", 
      "SUFFIX"   => "gz"
   },
   "EXE_FILES" => [
      "tools/lclean",
      "tools/ldat",
      "tools/lhalw",
      "tools/lls",
   ],
);

