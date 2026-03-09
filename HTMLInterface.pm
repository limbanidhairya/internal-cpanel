package Whostmgr::HTMLInterface;

#                                      Copyright 2025 WebPros International, LLC
#                                                           All rights reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited.



=encoding utf-8

=head1 NAME

Whostmgr::HTMLInterface - Core HTML interface generation for WHM

=head1 SYNOPSIS

    use Whostmgr::HTMLInterface;

    # Generate standard WHM header
    Whostmgr::HTMLInterface::defheader(
        'Page Title',
        'icon.gif',
        '/scripts/some_script',
        0,  # skipbreadcrumb
        0,  # skipheader
        0,  # hide_header
        0,  # inside_frame_or_tab_or_popup
        'yui'  # theme
    );

    # Create content blocks
    Whostmgr::HTMLInterface::brickstart('Configuration', 'center', '80%');
    print "Your content here";
    Whostmgr::HTMLInterface::brickend();

    # Generate standard WHM footer
    Whostmgr::HTMLInterface::deffooter();

=head1 DESCRIPTION

This module provides the core HTML interface generation functionality for WHM (Web Host Manager).
It handles the creation of standardized headers, footers, content blocks, and other UI elements
that maintain WHM's consistent look and feel across all administrative interfaces.

The module manages template processing, JavaScript/CSS loading, and ensures proper HTML structure
for WHM pages. It serves as the foundation for all WHM administrative interface generation.

=cut

use strict;
## no critic qw(TestingAndDebugging::RequireUseWarnings)

use Cpanel::LoadFile                   ();
use Cpanel::JSON                       ();
use Cpanel::Template                   ();
use Cpanel::Template::Plugin::Whostmgr ();
use Cpanel::Finally                    ();
use Cpanel::Version::Full              ();
use Whostmgr::Session                  ();    # PPI USE OK - used below

my $copyright;

BEGIN {
    $copyright = ( localtime(time) )[5] + 1900;
}

our $DISABLE_JSSCROLL = 0;

my %LOADED              = ( '/yui/container/assets/container.css' => 1 );    #now preloaded into the master css sheet
my $printed_jsscrollend = 0;
my $sentdefheader       = 0;
my $sentdeffooter       = 0;
my $brickcount          = 0;
my $ensure_deffooter;

# This variable sometimes holds a Cpanel::Finally.
# It needs to happen before global destruction.

END {
    undef $ensure_deffooter;
}

=head2 report_license_error

Displays a license error page and exits the program.

    Whostmgr::HTMLInterface::report_license_error($error_message);

This function processes and displays a standardized license error template,
optionally including server-specific error messages from the license error display file.

=over 4

=item * C<$error> - The license error message to display

=back

The function will exit with status 1 after displaying the error.

=cut

sub report_license_error {
    use Carp;
    open my $fh6, '>', '/tmp/license_trace.txt';
    print $fh6 Carp::longmess("Traced report_license_error call");
    close $fh6;
    my $error = shift;
    my $licservermessage;
    if ( -e '/usr/local/cpanel/logs/license_error.display' ) {
        $licservermessage = Cpanel::LoadFile::loadfile('/usr/local/cpanel/logs/license_error.display');
    }
    Cpanel::Template::process_template(
        'whostmgr',
        {
            'print'         => 1,
            'template_file' => '/usr/local/cpanel/base/unprotected/lisc/licenseerror_whm.tmpl',
            'data'          => {
                'liscerror'        => $error,
                'licservermessage' => $licservermessage
            },
        }
    );
    exit 1;
}

=head2 simpleheading

Generates a simple HTML heading.

    my $html = Whostmgr::HTMLInterface::simpleheading('Configuration Options');

Creates an H3 HTML heading element with the specified title text.

=over 4

=item * C<$head> - The heading text to display

=back

Returns: Prints the HTML heading directly to output.

=cut

sub simpleheading {
    my $head = shift;
    return print qq{<h3>$head</h3>};
}

=head2 deffooter

Generates the standard WHM footer.

    Whostmgr::HTMLInterface::deffooter();
    Whostmgr::HTMLInterface::deffooter($hide_header, $skipsupport, $inside_frame_or_tab_or_popup, $theme);

Processes and outputs the standardized WHM footer template. This function ensures
the footer is only rendered once per page load and handles cleanup of footer resources.

=over 4

=item * C<$hide_header> - (Optional) Boolean to hide header elements in footer

=item * C<$skipsupport> - (Optional) Boolean to skip support-related footer elements

=item * C<$inside_frame_or_tab_or_popup> - (Optional) Boolean for iframe/popup contexts

=item * C<$theme> - (Optional) Theme name (defaults to 'yui')

=back

This function automatically prevents duplicate footer rendering.

=cut

sub deffooter {
    undef $ensure_deffooter;
    return if $sentdeffooter++;
    Cpanel::Template::process_template(
        'whostmgr',
        {
            'print'                        => 1,
            'template_file'                => 'master_templates/_deffooter.tmpl',
            'hide_header'                  => $_[0] || undef,
            'skipsupport'                  => $_[1] || undef,
            'inside_frame_or_tab_or_popup' => $_[2] || undef,
            'theme'                        => $_[3] || "yui",
        },
    );

    return;
}

=head2 defheader

Generates the standard WHM header.

    Whostmgr::HTMLInterface::defheader(
        'Page Title',               # header title
        'icon.gif',                # icon filename
        '/scripts/some_script',    # breadcrumb URL
        0,                         # skipbreadcrumb
        0,                         # skipheader
        0,                         # hide_header
        0,                         # inside_frame_or_tab_or_popup
        'yui',                     # theme
        'app_key'                  # application key
    );

Processes and outputs the standardized WHM header template. This function ensures
the header is only rendered once per page load and automatically sets up footer cleanup.

=over 4

=item * C<$header> - The page title to display in the header

=item * C<$icon> - Icon filename to display (optional)

=item * C<$breadcrumburl> - URL for breadcrumb navigation (optional)

=item * C<$skipbreadcrumb> - Boolean to skip breadcrumb generation (optional)

=item * C<$skipheader> - Boolean to skip header generation (optional)

=item * C<$hide_header> - Boolean to hide header elements (optional)

=item * C<$inside_frame_or_tab_or_popup> - Boolean for iframe/popup contexts (optional)

=item * C<$theme> - Theme name (defaults to 'yui')

=item * C<$app_key> - Application key for plugin identification (optional)

=back

Additional arguments after index 8 are passed directly to the template as key/value pairs.

=cut

sub defheader {    ## no critic qw(Subroutines::RequireArgUnpacking)
    return if $sentdefheader++;

    my $hide_header                  = $_[5] || undef;
    my $inside_frame_or_tab_or_popup = $_[6] || undef;
    my $theme                        = $_[7] || 'yui';
    my $app_key                      = $_[8] || '';

    #Figure out what the app_key is if this is a plugin which neglected to pass appkey (pretty much all of them)
    if ( !$app_key ) {
        my $cf = '/var/cpanel/pluginscache.yaml';
        require Cpanel::CachedDataStore;
        my $plugindata = -e $cf && Cpanel::CachedDataStore::loaddatastore($cf);
        if ( ( ref $plugindata eq 'Cpanel::CachedDataStore' ) && ( ref $plugindata->{'data'}->{'addons'} eq 'ARRAY' ) ) {
            foreach my $app ( @{ $plugindata->{'data'}->{'addons'} } ) {
                next unless $app->{cgi} && $app->{uniquekey};
                if ( $_[2] =~ m/\Q$app->{cgi}\E$/ ) {
                    $app_key = "plugins_$app->{uniquekey}";
                    last;
                }
            }
        }
    }

    # Args after index 8 are key/value pairs passed directly to the template.

    $ensure_deffooter = Cpanel::Finally->new(
        sub {
            deffooter( $hide_header, undef, $inside_frame_or_tab_or_popup, $theme );
        }
    );

    Cpanel::Template::process_template(
        'whostmgr',
        {
            'print'                        => 1,
            'template_file'                => 'master_templates/_defheader.tmpl',
            'header'                       => $_[0] || undef,
            'icon'                         => $_[1] || undef,
            'breadcrumburl'                => $_[2] || undef,
            'skipbreadcrumb'               => $_[3] || undef,
            'skipheader'                   => $_[4] || undef,
            'hide_header'                  => $hide_header,
            'inside_frame_or_tab_or_popup' => $inside_frame_or_tab_or_popup,
            'theme'                        => $theme,
            'app_key'                      => $app_key,
            @_[ 9 .. $#_ ],
        },
    );

    return;
}

=head2 getbggif

Returns background GIF information.

    my $bg_info = Whostmgr::HTMLInterface::getbggif();

This is a legacy function that delegates to the Template Plugin's getbggif method.
Should be replaced with direct Template Plugin calls in new code.

Returns: Background GIF information from the WHM template plugin.

=cut

#should be removed once all the perl invocations of this are moved to TT
sub getbggif {
    return Cpanel::Template::Plugin::Whostmgr->getbggif();
}

=head2 starthtml

Generates the HTML document start.

    my $html = Whostmgr::HTMLInterface::starthtml(undef, 1, $extra_styles);
    Whostmgr::HTMLInterface::starthtml();

Processes the HTML document beginning template with optional custom styling.

=over 4

=item * C<$unused> - Unused parameter (legacy compatibility)

=item * C<$returnstr> - Boolean to return HTML string instead of printing

=item * C<$extrastyle> - Additional CSS styles to include

=back

Returns: HTML string if C<$returnstr> is true, otherwise prints directly.

=cut

sub starthtml {
    my ( undef, $returnstr, $extrastyle ) = @_;
    local $Cpanel::App::appname = 'whostmgr';    #make sure we get the right magic revision module

    my $sthtml = ${
        Cpanel::Template::process_template(
            'whostmgr',
            {
                'template_file' => '_starthtml.tmpl',
                'extrastyle'    => $extrastyle,
            },
        )
    };

    if ($returnstr) {
        $sthtml =~ s/\"/\\\"/g;
        return $sthtml;
    }
    else {
        print $sthtml;
    }
}

=head2 brickstart

Starts a content brick container.

    Whostmgr::HTMLInterface::brickstart('Configuration', 'center', '80%', 5);
    Whostmgr::HTMLInterface::brickstart('Status');  # uses defaults

Creates the opening HTML for a standardized content container ("brick") used
throughout WHM interfaces. Bricks provide consistent styling and layout.

=over 4

=item * C<$title> - The title to display in the brick header

=item * C<$align> - Text alignment (defaults to 'center')

=item * C<$percent> - Width percentage (defaults to '100%')

=item * C<$padding> - Internal padding value (defaults to '5')

=back

Must be paired with L</brickend> to close the container properly.

=cut

sub brickstart {
    my ( $title, $align, $percent, $padding ) = @_;
    if ( !defined $percent ) { $percent = '100%'; }
    if ( !defined $align )   { $align   = 'center'; }
    if ( !defined $padding ) { $padding = '5'; }

    $brickcount++;

    my $brick_r = Cpanel::Template::process_template(
        'whostmgr',
        {
            'print'         => 0,
            'template_file' => 'brickstart.tmpl',
            'brickalign'    => $align,
            'brickpadding'  => $padding,
            'brickpercent'  => $percent,
            'bricktitle'    => $title,
        },
    );

    require Whostmgr::HTMLInterface::Output;
    Whostmgr::HTMLInterface::Output::print2anyoutput( ${$brick_r} );

    return;
}

=head2 brickend

Ends a content brick container.

    Whostmgr::HTMLInterface::brickend();

Closes a content container opened by L</brickstart>. This generates the
closing HTML tags and formatting for the brick structure.

Must be called after L</brickstart> to maintain proper HTML structure.

=cut

sub brickend {
    my $brick_r = Cpanel::Template::process_template(
        'whostmgr',
        {
            'print'         => 0,
            'template_file' => 'brickend.tmpl',
        },
    );

    require Whostmgr::HTMLInterface::Output;
    Whostmgr::HTMLInterface::Output::print2anyoutput( ${$brick_r} );

    return;
}

=head2 htmlexec

Delegates to HTMLInterface::Exec for command execution display.

    Whostmgr::HTMLInterface::htmlexec(@args);

This function provides access to HTML-formatted command execution functionality
by delegating to the Whostmgr::HTMLInterface::Exec module.

=cut

sub htmlexec {
    require Whostmgr::HTMLInterface::Exec;
    goto &Whostmgr::HTMLInterface::Exec::htmlexec;
}

=head2 print_results_message

Displays a formatted results message.

    Whostmgr::HTMLInterface::print_results_message(\%message_data);

Processes and displays a standardized results message template with the provided data.

=over 4

=item * C<$data> - Hash reference containing message data for the template

=back

The data structure should contain keys expected by the print_results_message template.

=cut

sub print_results_message {

    Cpanel::Template::process_template(
        'whostmgr',
        {
            'template_file' => 'print_results_message.tmpl',
            'data'          => shift(),
        }
    );

    return;
}

=head2 load_statusbox

Loads the status box interface for long-running operations.

    Whostmgr::HTMLInterface::load_statusbox('myapp');

Initializes the status box UI component used to display progress for operations
that take significant time to complete. Only loads when in CGI environment.

=over 4

=item * C<$appname> - Application name for status tracking

=back

Returns: 1 on successful load, undef if not in CGI environment.

=cut

sub load_statusbox {
    my $appname = shift;
    return if ( -t STDOUT || !defined $ENV{'GATEWAY_INTERFACE'} || $ENV{'GATEWAY_INTERFACE'} !~ m/CGI/i );
    local $Cpanel::App::appname = 'whostmgr';    #make sure we get the right magic revision module
    load_css('/yui/container/assets/container.css');
    load_js('/js/statusbox.js');
    print qq{<div id=sdiv></div>};
    print qq{<script>whmappname='$appname';</script>};
    print qq{ } x 4096;
    print "\n";

    return 1;
}

=head2 load_js

Loads a JavaScript file with magic revision URL.

    Whostmgr::HTMLInterface::load_js('/js/statusbox.js');

Loads a JavaScript file if not already loaded, using magic revision URL generation
for cache busting. Prevents duplicate loading of the same script.

=over 4

=item * C<$script> - Path to the JavaScript file to load

=back

Returns: 1 on successful load, undef if already loaded.

=cut

sub load_js {
    my $script = shift;
    if ( exists $LOADED{$script} ) { return; }
    $LOADED{$script} = 1;
    local $Cpanel::App::appname = 'whostmgr';    #make sure we get the right magic revision module

    require Cpanel::MagicRevision;
    print qq{<script type="text/javascript" src="} . Cpanel::MagicRevision::calculate_magic_url($script) . qq{"></script>\n};
    return 1;
}

=head2 load_css

Loads a CSS file with magic revision URL.

    Whostmgr::HTMLInterface::load_css('/css/styles.css');

Loads a CSS file if not already loaded, using magic revision URL generation
for cache busting. Prevents duplicate loading of the same stylesheet.

=over 4

=item * C<$css> - Path to the CSS file to load

=back

Returns: 1 on successful load, undef if already loaded.

=cut

sub load_css {
    my $css = shift;
    if ( exists $LOADED{$css} ) { return; }
    $LOADED{$css} = 1;
    local $Cpanel::App::appname = 'whostmgr';    #make sure we get the right magic revision module
    require Cpanel::MagicRevision;
    print qq{<link rel="stylesheet" type="text/css" href="} . Cpanel::MagicRevision::calculate_magic_url($css) . qq{" />};

    return 1;
}

=head2 jsscrollend

Adds JavaScript to scroll to the end of the page.

    Whostmgr::HTMLInterface::jsscrollend();

Generates and outputs JavaScript code that scrolls the browser window to the
bottom of the page. Used for long-running operations where output is continuously
added to maintain visibility of the latest content.

The function is disabled when C<$DISABLE_JSSCROLL> is set and only runs in
non-TTY environments.

=cut

sub jsscrollend {
    return if $DISABLE_JSSCROLL;

    my $jscode = '<script>
     function scrollend() {
         var scrollEnd;
         if (window.scrollHeight) {
            scrollEnd=window.scrollHeight;
         } else if (document.body.scrollHeight) {
            scrollEnd=document.body.scrollHeight;
         } else {
            scrollEnd=100000000;
         }
         window.scroll(0,scrollEnd);
     }
     </script>';

    my $on_a_tty = -t STDIN && -t STDOUT;
    if ( !$printed_jsscrollend ) {
        syswrite( STDOUT, $jscode ) if !$on_a_tty;    #no buffering
        $printed_jsscrollend = 1;
    }
    syswrite( STDOUT, '<script>window.setTimeout(scrollend,180);</script>' ) if !$on_a_tty;    #no buffering
    return;
}

=head2 sendfooter

Sends appropriate footer based on context.

    Whostmgr::HTMLInterface::sendfooter('script_name');

Determines and outputs the appropriate footer content based on the current
context and script being executed. Some scripts receive simplified footers
for API compatibility.

=over 4

=item * C<$prog> - The program/script name being executed

=back

For most scripts, this delegates to L</deffooter>. For specific scripts
(API endpoints, certain utilities), it outputs a simplified copyright footer.

=cut

sub sendfooter {
    my $prog = shift;

    return             if $sentdeffooter;
    return deffooter() if $sentdefheader && !$sentdeffooter;

    if ( $prog !~ /(?:wml|remote_|getlangkey|addpkg|editpkg|killpkg|killacct|showversion|wwwacct|gethostname)/ ) {    # for cPanel::PublicAPI compat see CPANEL-876
        print qq{<!-- Web Host Manager } . Cpanel::Version::Full::getversion() . qq{ [$Whostmgr::Session::binary] (c) cPanel, L.L.C. $copyright
            http://cpanel.net/  Unauthorized copying is prohibited -->\n};
    }

    return;
}

=head2 redirect

Performs a JavaScript-based page redirect.

    Whostmgr::HTMLInterface::redirect('/scripts/main');

Generates JavaScript code to redirect the browser to the specified URL.
The URL is properly JSON-encoded to prevent injection attacks.

=over 4

=item * C<$uri> - The URI to redirect to

=back

This method is preferred over HTTP redirects in contexts where HTML has
already been output to the browser.

=cut

sub redirect {
    my ($uri) = @_;

    my $json_uri = Cpanel::JSON::Dump($uri);

    print <<EOM;

<script type="text/javascript">window.location.href=$json_uri;</script>

EOM
    return;
}

=head2 js_security_token

Legacy function that returns empty string.

    my $token = Whostmgr::HTMLInterface::js_security_token();

This function is maintained for backward compatibility but no longer
provides security token functionality. Always returns an empty string.

Returns: Empty string

=cut

#legacy, unneeded
sub js_security_token { return q{} }

1;
