#!/usr/bin/env perl
# Vendored from https://github.com/devert/rex-fzf-url (bin/extract-urls.pl).
#
# MIT License
#
# Copyright (c) 2026 Dennis Evert
# Copyright (c) 2018 Wenxuan Zhang (wfxr/tmux-fzf-url)
# Copyright (c) 2026 Caspar Nettelbladt (kaar/herdr-fzf-url)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# extract-urls — read terminal text on stdin, print one URL per line,
# deduplicated, in order of appearance. ANSI/OSC escapes are stripped first.
#
# The patterns are ports of wfxr/tmux-fzf-url's `xre` extraction (MIT);
# this perl implementation is adapted from kaar/herdr-fzf-url (MIT).
#
# Patterns run as one alternation per line, so an earlier match consumes its
# text and a later pattern cannot re-match inside it (https://www.example.com
# is one URL, not also a www match). Priority order:
#
#   URL  https/http/ftp/file URLs, kept verbatim
#   GIT  git@host:path / ssh://git@host/path  -> https://host/path
#   WWW  bare www. domains                    -> http://www...
#   IP   v4 address, optional port and path   -> http://1.2.3.4...
#   GH   quoted 'user/repo' shorthand         -> https://github.com/user/repo
#
# Arguments: extra patterns as pairs, REGEX URL [REGEX URL ...].
# REGEX is a perl regex. URL is the URL to build from each match, where
# $0-$9 refer to capture groups. An empty URL emits the matched text.
use strict;
use warnings;

die "extract-urls: extra patterns need REGEX URL pairs\n" if @ARGV % 2;
my @extras;
while (my ($regex, $url) = splice(@ARGV, 0, 2)) {
    push @extras, [qr/$regex/, $url];
}

my %seen;
sub emit { my ($url) = @_; print "$url\n" unless $seen{$url}++ }

# Drop closing brackets and sentence punctuation that follow a URL in prose,
# such as the ")" in "(git@github.com:user/repo.git)".
sub trim { my ($s) = @_; $s =~ s/[)\]}>.,;:!?]+$//; return $s }

while (my $line = <STDIN>) {
    $line =~ s/\e\[[0-9;?]*[a-zA-Z]//g;      # CSI: colors, cursor movement
    $line =~ s/\e\]8;[^;\a\e]*;([^\a\e]*)(?:\a|\e\\)/ $1 /g;  # OSC 8: keep hyperlink targets
    $line =~ s/\e\][^\a\e]*(?:\a|\e\\)?//g;  # other OSC: titles, etc.

    while (
        $line =~ m{
            (?<url>(?:https?|ftp|file):/?//[-\w+&\@\#/%?=~|!:,.;]*[-\w+&\@\#/%=~|])
          | (?:ssh://)?git\@(?<git_host>[^\s'"`:]+)[:/](?<git_path>[^\s'"`]+)
          | (?<www>www\.[a-zA-Z](?:-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}(?:/[^\s'"`]+)*)
          | (?<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?::\d{1,5})?(?:/[^\s'"`]+)*)
          | ['"](?<gh>[\w-]+/[\w.-]+)['"]
        }gx
    ) {
        if    (defined $+{url})      { emit($+{url}) }
        elsif (defined $+{git_host}) { emit(trim("https://$+{git_host}/$+{git_path}")) }
        elsif (defined $+{www})      { emit(trim("http://$+{www}")) }
        elsif (defined $+{ip})       { emit(trim("http://$+{ip}")) }
        else                         { emit("https://github.com/$+{gh}") }  # each match sets one group
    }

    for my $extra (@extras) {
        my ($re, $url) = @$extra;
        while ($line =~ /$re/g) {
            if (length $url) {
                my @g = ($&, $1, $2, $3, $4, $5, $6, $7, $8, $9);
                (my $out = $url) =~ s{\$(\d)}{ defined $g[$1] ? $g[$1] : '' }ge;
                emit($out);
            }
            else { emit($&) }
        }
    }
}
