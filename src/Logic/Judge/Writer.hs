{-|
Module      : Logic.Judge.Writer
Description : Producing output.
Copyright   : (c) 2017, 2018 N Steenbergen
License     : GPL-3
Maintainer  : ns@slak.ws
Stability   : experimental

This module contains operations and class instances for writing to files or 
terminals.
-}

{-# LANGUAGE PackageImports #-}
module Logic.Judge.Writer 
    ( Format(LaTeX, Plain)
    , writeHeader
    , writeBody
    , writeFooter
    , write
    , plainprint
    , prettyprint
    ) where

import "base" GHC.IO.Handle (Handle, hIsTerminalDevice)
import "base" GHC.IO.Handle.FD (stdout, stderr)
import "bytestring" Data.ByteString (hPut)
import "terminal-size" System.Console.Terminal.Size (size, width)
import qualified "ansi-wl-pprint" Text.PrettyPrint.ANSI.Leijen as PP
import qualified "utf8-string" Data.ByteString.UTF8 as UTF8

import Logic.Judge.Writer.Plain (Printable, pretty)
import Logic.Judge.Writer.LaTeX (LaTeX, latexHeader, latexFooter, latex)

-- | A data type representing the supported file formats.
data Format 
    = LaTeX 
    | Plain 
    deriving (Show, Read)


-- | Write the header associated with a file format to a file.
writeHeader :: Handle -> Format -> IO ()
writeHeader file format = case format of
    LaTeX -> write file latexHeader
    _ -> return ()


-- | Write an object to a file in the given format.
writeBody :: (LaTeX a, Printable a) => Handle -> Format -> a -> IO ()
writeBody file format = write file . case format of
    LaTeX -> latex
    Plain -> pretty


-- | Write the footer associated with a file format to a file.
writeFooter :: Handle -> Format -> IO ()
writeFooter file format = case format of
    LaTeX -> write file latexFooter
    _ -> return ()


-- | Write a document to some file handle. Automatically chooses `prettyprint`
-- or `plainprint` based on whether we are writing to a terminal or not.
write :: Handle -> PP.Doc -> IO ()
write file doc = do
    terminal <- hIsTerminalDevice file
    if terminal
        then prettyprint file doc
        else plainprint file doc


-- | Print ANSI-colorised document to file handle.
prettyprint :: Handle -> PP.Doc -> IO ()
prettyprint file doc = do
    columns <- maybe 79 width `fmap` size
    PP.displayIO file 
        . (PP.renderPretty 1.0 columns) 
        . (PP.<> PP.line)
        . PP.fill columns
        $ doc


-- | Print UTF-8 encoded, plain document to file handle.
plainprint :: Handle -> PP.Doc -> IO ()
plainprint file doc = hPut file 
    . UTF8.fromString
    . flip PP.displayS "" 
    . (PP.renderPretty 1.0 255) 
    . PP.plain
    . (PP.<> PP.line)
    $ doc

