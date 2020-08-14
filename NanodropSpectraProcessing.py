# -*- coding: utf-8 -*-
"""
Spyder Editor
O.Yeung 07/2018

Reads nanodrop dataset workbook output files (.tsv)
Searches output data for individual dataset headings
Splits workbook into individual spectrum files (.txt)
Formats individual spectrum files "[filename]["R(x)"]" per repeat
e.g.    Filename = "Lin1-25.tsv"
            Processed filenames = "Lin1-25.tsvR1", "Lin1-25.tsvR2", etc
            
>>>>Run in same directory as files to be processed
Run via compiling to .exe or .bat command file 
"""

#import os for operating system dependent functionality
import os

#define overall function split_file
def split_file(name, lines_per_chunk, chunks_per_file):

#define subfunction write_split to write output txt file  
    def write_split(chunk_no, chunk):
        with open("{}R{}.txt".format(name,chunk_no), "w") as outfile:
            outfile.write("".join(i for i in chunk))
            
#state variables            
    count, chunk_no, chunk_count, chunk = 1, 1, 0, []

#Start function loop
    with open(name, "r") as f:
        for row in f:
            if count > lines_per_chunk and row == "\n":
                chunk_count += 1
                count = 1
                
#if fucntion for if chunk count meets user defined variable for chunks in one file                    
                if chunk_count == chunks_per_file:  
                    write_split(chunk_no, chunk)
                    chunk = []
                    chunk_count = 0
                    chunk_no += 1

#if a row contains line break -> move to next line do not append chunk. else -> append chunk                   
            else:
                if row == "\n":
                    count += 1
                else:
                    count += 1
                    chunk.append(row)
    if chunk:
        write_split(chunk_no, chunk)

#autoscan for .tsv files
for file in os.listdir():
    if file.endswith(".tsv"):
        split_file(os.path.join(file), 1, 1)
