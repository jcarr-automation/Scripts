#!/usr/bin/perl
# macSideBar
#
# This program is meant to run continuously in the console.
# The goal is to give constant, decent "reading material"
# Output can include, but is not limited to:
# 1. Random lines from a text file
# 2. RSS feeds
# 3. Weather reports
# 4. DB SELECT results (not implemented)
# 5. Stock Quotes
use strict;
use warnings;
use XML::RSS::Parser;
use FileHandle;
use WWW::Mechanize;
use Term::ProgressBar;
use Term::ANSIColor;
my $mech = WWW::Mechanize->new();

# !! NOTE 10/29/2020 - if you get the error:
#    "Can't verify SSL peers without knowing which Certificate Authorities to trust"
# !! You need to install the module: Mozilla::CA

$|=1;

# Set my PROXY user credentials!!
#$mech->proxy(
#	['http','ftp'],
#	'http://username:password@proxy.server.com:8080'
#);

my @textFiles = (
	"quotefiles/twainquotes.txt",
	"quotefiles/suntzu.txt",
	"quotefiles/MJDsFileOfGoodAdviceForSidebar.txt",
	"quotefiles/qabumperstickers.txt"
);

my @rssFeeds = (
#	'www.reddit.com/.rss',
#	'articlefeeds.nasdaq.com/nasdaq/symbols?symbol=SPOK',
	'www.startribune.com/rss/?sf=1&s=/',
#	'www.marketwatch.com/rss/marketpulse',
	'rss.slashdot.org/Slashdot/slashdot',
	'www.startribune.com/sports/index.rss2',
#	'www.health.state.mn.us/news/rss/news.xml',
#	'kuathletics.com/rss.aspx?path=mbball'
#	'w1.weather.gov/xml/current_obs/KFCM.rss'#,
#	'feeds.nytimes.com/nyt/rss/Technology',
#	'www.kansascity.com/news/index.xml'
);

# Main Program
my $rssC = 3;
my %Rss = ();
while(1){
	# Text Files
	# Slurp text into an array, then output random member of the array
	foreach my $f ( @textFiles ) {
		my @t = ();
		open TX, $f || die $!;
		while(<TX>){
			push(@t, $_) if $_ =~ /\w/
		}
		close TX;
		print color('cyan');
		Type($t[int(rand(@t))]."\n");
		print color('reset');
	}
	
	# Stock Ticker
	
	# Weather Update

	# RSS Update
	if( $rssC == 3 ) {
		#Type("\nUPDATING FEEDS...\n\n");
		%Rss = ();

		my $progress_bar = Term::ProgressBar->new({
				count => scalar(@rssFeeds),
				name => "Updating Feeds"
			});
		my $progCount = 0;

		for(my $r=0;$r<@rssFeeds;$r++){

			$progress_bar->update($r+1);

			my $tempFile = 'tempRSS.txt';
			$mech->get( 'http://'.$rssFeeds[$r] );
			my $rawFeed = $mech->content;
			$rawFeed =~ s/[^[:ascii:]]+//g;  # get rid of non-ASCII characters
			
			open FILE, ">", $tempFile or die "Temp RSS: $!\n";
			print FILE $rawFeed."\n";
			close FILE;
			
			my $p = XML::RSS::Parser->new;
			my $fh = FileHandle->new( $tempFile );
			my $feed = $p->parse_file($fh) or print $rssFeeds[$r].'--'.$!."\n\n" and next;		 
			my $feed_title = $feed->query('/channel/title');			
			my $count = $feed->item_count;
			
			$Rss{$feed_title->text_content}->{COUNT} = $count;
			
			my $fc = 0;
			foreach my $i ( $feed->query('//item') ) {
				$fc++;
				my $node = $i->query('title');				
				my $descNode = $i->query('description');
				
				my $cleanText = '';
				
				my $scrub = $descNode->text_content;
				$scrub =~ s/<(?:[^>'"]*|(['"]).*?\g1)*>//gs;
				
				if (length($scrub)<350) {
					$cleanText = $scrub;
				} else {
					$cleanText = substr($scrub,0,350)."...(cont'd)...";
				}
				
				$Rss{$feed_title->text_content}{$fc}->{TITLE} = $node->text_content;
				$Rss{$feed_title->text_content}{$fc}->{TEXT} = $cleanText;
			}	
		}
	}
	
	if($rssC>3){$rssC=0}else{$rssC++}
	
	# RSS Display
	next unless %Rss;
	foreach my $feed (keys %Rss) {
		sleep(1);
		print color('magenta');
		Type(
			$feed.
			" ($Rss{$feed}{COUNT})".
			'.....'."\n\n"
		);
		print color('reset');
		sleep(1);
		
		# if there are more than 15, display a subset
		my $count = 0;		
		foreach my $item ( sort keys %{$Rss{$feed}} ) {
			$count++;
			last if $count > 15;
			next unless $item =~ /\d+/;
			sleep(3);
			Type("** ".$Rss{$feed}{$item}{TITLE}." **\n");
			select(undef, undef, undef, 0.50);
			
			# Clean the text up
			$Rss{$feed}{$item}{TEXT} =~ s/[^\w\s'"-:;!,\.\?\$\%\@]//g;
			$Rss{$feed}{$item}{TEXT} =~ s/\n//g;

			print color('yellow');
			print $Rss{$feed}{$item}{TEXT}."\n\n";
			print color('reset');
		}
	}
}

sub Type {
	my $t = shift;
	my @ch = split(//,$t);
	foreach my $c (@ch) {
		next unless $c =~ /[\w\s'"-:;!,\.\?\$\%\@]/;
		print $c and select(undef,undef,undef,0.05);
	}
}
