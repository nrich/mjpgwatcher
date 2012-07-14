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
 
-o ('%H.%P.%E')
    Format string describing converted output video files. 
    
    * %H - hostname of capture stream
    * %P - port of capture stream
    * %E - current epoch time
    * %Y - current year in YYYY
    * %m - current month in mm
    * %d - current day of month in dd
    * %h - current hour
    * %m - current minute
    * %s - current second    

