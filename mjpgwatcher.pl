#!/usr/bin/perl -w

use strict;
use GD qw//;
use Getopt::Std qw/getopt/;
use File::Basename qw/basename/;
use Cwd qw/cwd/;
use Time::HiRes qw/sleep/;
use POSIX qw/strftime/;

use LWP::UserAgent qw//;

use threads qw//;
use Thread::Queue qw//;
use threads::shared qw//;

my $still_running : shared = 1;

use vars qw/$opt_s $opt_t $opt_d $opt_f $opt_e $opt_o/;
getopt('s:t:d:f:e:o:');

main(@ARGV);

sub main {
    my (@cam_urls) = @_;

    $opt_s ||= 5 * 1024 * 1024;
    $opt_t ||= '/tmp';
    $opt_d ||= './';
    $opt_f ||= 10;
    $opt_e ||= 'avi';
    $opt_o ||= '%H.%P.%E';

    for my $cam_url (@cam_urls) {
        $cam_url =~ /^(https?):\/\/([^:]+)(?:\:(\d+))?\//;

        my $proto = $1;
        my $host = $2;
        my $port = $3 || ($proto eq 'https' ? 443 : 80);

        my $data_queue = Thread::Queue->new(); 
        my $conversion_queue = Thread::Queue->new(); 

        threads->create(
            'writer_thread',
	    $opt_s,
            $opt_t,
            $opt_o,
            $host,
            $port,
            $data_queue,
            $conversion_queue,
        )->detach();

        threads->create(
            'converter_thread',
            $opt_d,
            $opt_f,
            $opt_e,
            $conversion_queue,
        )->detach();

        threads->create(
            'downloader_thread',
            $cam_url,
            $data_queue,
        )->detach();
    }

    while(1) {
        sleep 10;
    }
}

sub downloader_thread {
    my ($url, $data_queue) = @_;

    my $ua = LWP::UserAgent->new();

    $ua->get(
        $url,
        'read_size_hint' => 10 * 1024,
        ':content_cb' => sub {
            my ($data, $response) = @_;

            $data_queue->enqueue($data);
        },
    );
}

sub writer_thread {
    my ($max_size, $tmp_dir, $format, $host, $port, $data_queue, $conversion_queue) = @_;

    my $fh = get_file($tmp_dir, $format, $host, $port);

    while (1) {
        while (my $data = $data_queue->dequeue_nb()) {
            print $fh $data;

            if (-s $fh > $max_size) {
                my $filename = filename_from_handle($fh);
                $conversion_queue->enqueue($filename);

                close $fh;

                $fh = get_file($tmp_dir, $format, $host, $port);
            }

	    threads->yield();
        }
    }
}

sub converter_thread {
    my ($dest_dir, $framerate, $extension, $conversion_queue) = @_;

    while (1) {
        while (my $filename = $conversion_queue->dequeue_nb()) {
            (my $outfile = basename $filename) =~ s/\.mjpg$/.$extension/g;
    
            system qw/ffmpeg -r/, $framerate, '-i', $filename, "$dest_dir/$outfile";
            unlink $filename;
        }
    }
}

sub get_file {
    my ($tmp_dir, $format, $host, $port) = @_;

    my ($year, $month, $day, $hour, $minute, $second) = split ':', strftime('%Y:%m:%d:%H:%M:%S', localtime());

    $format =~ s/%H/$host/g;
    $format =~ s/%P/$port/g;
    $format =~ s/%E/time()/ge;

    $format =~ s/%Y/$year/g;
    $format =~ s/%m/$month/g;
    $format =~ s/%d/$day/g;
    $format =~ s/%H/$hour/g;
    $format =~ s/%M/$minute/g;
    $format =~ s/%S/$second/g;

    my $filename = "$tmp_dir/$format.mjpg";

    open my $fh, '>', $filename or die "Could not open `$filename': $!";
 
    return $fh;
}

sub filename_from_handle {
    my ($fh) = @_;

    my $fd = fileno $fh;
    return readlink("/proc/$$/fd/$fd");
}
