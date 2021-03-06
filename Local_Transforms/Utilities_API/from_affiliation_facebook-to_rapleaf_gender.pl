#!/usr/bin/env perl
# The above shebang is for "perlbrew", otherwise replace with "/usr/bin/perl" and update the "use lib '[Insert CPAN Module Path]'" line.
#
# Please refer to the Plain Old Documentation (POD) at the end of this Perl Script for further information

# perltidy: 20121226
# ci - cmd_line: 20121226

# TODO Refactor "perl-maltego.pl" as a module
do '../Perl-Maltego/perl-maltego.pl' or die $@;

# Perl v5.8 is the minimum version required for 'use autodie'
# Perl v5.8.1 is the minimum version required for 'use utf8'
use 5.0080001;
use v5.8.1;

# use lib '[Insert CPAN Module Path]';

use warnings FATAL;
use diagnostics;

use utf8;

use HTTP::Tiny;     # HTTP::Tiny v0.024
use JSON;           # JSON v2.53
use URI::Escape;    # URI::Escape v3.31
use Config::Std;    # Config::Std v0.900

# TODO use autodie qw(:all);
use autodie;

# use Smart::Comments;

my $VERSION = "0.2_13"; # May be required to upload script to CPAN i.e. http://www.cpan.org/scripts/submitting.html

# CONFIGURATION
# REFACTOR with "easydialogs" e.g. http://www.paterva.com/forum//index.php/topic,134.0.html as recommended by Andrew from Paterva
read_config "../etc/Rapleaf_API.conf" => my %config;
my $API_KEY = $config{'RapleafAPI'}{'api_key'};

# "###" is for Smart::Comments CPAN Module
### \$API_KEY is: $API_KEY;

# https://www.rapleaf.com/developers/utilities-api/utilities-api-documentation/#responses
my $http_status_200 = "OK";
my $http_status_400 = "Bad Request";
my $http_status_403 = "Forbidden";
my $http_status_500 = "Internal Server Error";

$ua = HTTP::Tiny->new(

    # TODO Transition from LWP::UserAgent to HTTP::Tiny
    # "timeout" attribute of https://metacpan.org/module/HTTP%3a%3aTiny#new
    timeout => "2",

    # "agent" attribute of https://metacpan.org/module/HTTP%3a%3aTiny#new
    agent => "RapleafApi/Perl/1.1"
);

my $maltego_selected_entity_value = $ARGV[0];

# "###" is for Smart::Comments CPAN Module
### \$maltego_selected_entity_value is: $maltego_selected_entity_value;

$maltego_selected_entity_value = trim($maltego_selected_entity_value);

# "###" is for Smart::Comments CPAN Module
### \$maltego_selected_entity_value is: $maltego_selected_entity_value;

my $maltego_additional_field_values = $ARGV[1];

# "###" is for Smart::Comments CPAN Module
### \$maltego_additional_field_values is: $maltego_additional_field_values;

my %maltego_additional_field_values =
  split_maltego_additional_fields($maltego_additional_field_values);

# TODO If UID field is empty, then extract UID from the "Profile URL" field
my $affilation_facebook_name = $maltego_additional_field_values{"person.name"};

# "###" is for Smart::Comments CPAN Module
### \$affilation_facebook_name is: $affilation_facebook_name;

$affilation_facebook_name = trim($affilation_facebook_name);

# "###" is for Smart::Comments CPAN Module
### \$affilation_facebook_name is: $affilation_facebook_name;

my @affilation_facebook_name = split( / /, $affilation_facebook_name );
$affilation_facebook_first_name = $affilation_facebook_name[0];

# "###" is for Smart::Comments CPAN Module
### \$affilation_facebook_first_name is: $affilation_facebook_first_name;

$affilation_facebook_first_name = uri_escape($affilation_facebook_first_name);

# "###" is for Smart::Comments CPAN Module
### \$maltego_selected_entity_value is: $maltego_selected_entity_value;

@maltego_ui =
  ( "Inform", "To Rapleaf Gender (Utilities API) - Local Transform v$VERSION" );

my $response = query_by_name($affilation_facebook_first_name);

# "###" is for "Smart::Comments CPAN Module
### \$response->{gender} is :$response->{gender}
### \$response->{likelihood} is :$response->{likelihood}

maltego_ui(@maltego_ui);

print("\t<Entities>\n");
if ( $response->{gender} eq "Male" ) {
    print("\t\t<Entity Type=\"cmlh.rapleaf.gender.male\"><Value>%");
    printf "%.0f", ( $response->{likelihood} * 100 );
    print("</Value>\n");
}

# TODO $response->{gender} is "unknown" i.e. https://www.rapleaf.com/developers/api_docs/utilities#name_to_gender

if ( $response->{gender} eq "Female" ) {
    print("\t\t<Entity Type=\"cmlh.rapleaf.gender.female\"><Value>%");
    printf "%.0f", ( $response->{likelihood} * 100 );
    print("</Value>\n");
}

print("\t\t\t<AdditionalFields>\n");
print("\t\t\t\t<Field Name=\"gender\">$response->{gender}</Field>\n");
print("\t\t\t\t<Field Name=\"likelihood\">$response->{likelihood}</Field>\n");
print("\t\t\t</AdditionalFields>\n");
print("\t\t</Entity>\n");
print("\t</Entities>\n");

maltego_message_end();

sub query_by_name {

    # Takes an e-mail that has already been hashed by sha1
    # and returns a hash which maps attribute fields onto attributes
    my $name = $_[0];
    my $url =
      "http://api.rapleaf.com/v4/util/name_to_gender/$name?api_key=$API_KEY";

    # "###" is for Smart::Comments CPAN Module
    ### \$url is: $url;
    __get_json_response($url);
}

sub __get_json_response {

    # Takes a url and returns a hash mapping attribute fields onto attributes
    # Note that an exception is raised in the case that
    # an HTTP response code other than 200 is sent back
    # The error code and error body are put in the exception's message
    my $json_response = $ua->get( $_[0] );
    if ( $json_response->{success} != "1" ) {

		# TODO Leverage other Maltego UI Messages, such as "Partial Error"
		# depending on the HTTP Status Code returned by Rapleaf i.e.
		# https://www.rapleaf.com/developers/utilities-api/utilities-api-documentation/#responses
        push( @maltego_ui, "Fatal Error", "$json_response->{content}" );
        maltego_ui(@maltego_ui);
        print STDERR "HTTP Status Code $json_response->{status}";
        maltego_error_no_entities_to_return();
        exit();
    }
    $json = JSON->new->allow_nonref;
    my $personalization = $json->decode( $json_response->{content} )->{answer};
}

=head1 NAME

from_affiliation_facebook-to_rapleaf_gender.pl - "To Rapleaf Gender - Maltego Local Transform"

Forked from https://github.com/Rapleaf/Personalization-Dev-Kits/blob/master/perl/RapleafApi.pl

=head1 VERSION

This documentation refers to "To Rapleaf Gender - Maltego Local Transform" Alpha $VERSION

=head1 CONFIGURATION

See the associated #CONFIGURATION Tag

Please refer to https://github.com/cmlh/Maltego-Rapleaf/wiki for further information 

=head1 MALTEGO CONFIGURATION

Please refer to https://github.com/cmlh/Maltego-Rapleaf/wiki for further information 

=head1 USAGE

Please refer to https://github.com/cmlh/Maltego-Gravatar/wiki for further information 

=head1 REQUIRED ARGUEMENTS

"Affiliation - Facebook" Entity

=head1 OPTIONAL ARGUEMENTS

=head1 DESCRIPTION

Please refer to https://github.com/cmlh/Maltego-Rapleaf/README.pod

=head1 CONTRIBUTION

Based on the "Apache License 2.0" Perl Code listed at https://raw.github.com/Rapleaf/Personalization-Dev-Kits/master/perl/RapleafApi.pl

=head1 DEPENDENCIES

=head2 CPAN Modules

HTTP::Tiny
JSON
Config::Std
Smart::Comments

=head2 Rapleaf API Key

https://dashboard.rapleaf.com/api_signup

https://github.com/cmlh/Maltego-Rapleaf/wiki/Overview-of-Rapleaf-APIs

=head2 MALTEGO

v3.3.0 "Radium" "Service Pack 2"

=head1 OSNAMES

osx

=head1 SCRIPT CATEGORIES

Web

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please refer to the comments beginning with "TODO" in the Perl Code.

=head1 AUTHOR

Christian Heinrich

=head1 CONTACT INFORMATION

http://cmlh.id.au/contact

=head1 MAILING LIST

=head1 REPOSITORY

https://github.com/cmlh/Maltego-Rapleaf

=head1 FURTHER INFORMATION AND UPDATES

http://cmlh.id.au/tagged/maltego

=head1 LICENSE AND COPYRIGHT

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 

Copyright 2012 Christian Heinrich
