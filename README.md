mjpgwatcher
===========

Simple perl script to grab MJPG video streams and convert the data into another video format.

Requirements:
    * Perl
    * ffmpeg

Options: 

-s (5)
    Size (in MB) of stream buffer to capture before conversion.

-t (/tmp)
    Directory to write temporary .mjpg stream buffer.

-d (./)
    Directory to write converted output files.

-f (10)
    Frame rate of converted output video files.

-e (avi)
    Extension (and file format) of converted output video files.
 
-o ('HOST.PORT.EPOCH')
    Format string describing converted output video files. 
    
    * HOST - hostname of capture stream
    * PORT - port of capture stream
    * EPOCH - current epoch time

    The format string is also bassed to strftime.
