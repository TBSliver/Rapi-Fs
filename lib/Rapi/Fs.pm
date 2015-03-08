package Rapi::Fs;

use strict;
use warnings;

use RapidApp 1.0010_08;

use Moose;
extends 'RapidApp::Builder';

use Types::Standard qw(:all);

use RapidApp::Util ':all';
use File::ShareDir qw(dist_dir);
use FindBin;

our $VERSION = '0.01';

has 'mounts', is => 'ro', isa => ArrayRef, required => 1;
has 'filetree_params', is => 'ro', isa => HashRef, default => sub {{}};

has 'share_dir', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  try{dist_dir(ref $self)} || 
    -d "$FindBin::Bin/share" ? "$FindBin::Bin/share" : "$FindBin::Bin/../share" ;
};

sub _build_version { $VERSION }
sub _build_plugins { ['RapidApp::TabGui'] }

sub _build_config {
  my $self = shift;
  
  my $tpl_dir = join('/',$self->share_dir,'templates');
  -d $tpl_dir or die "template dir ($tpl_dir) not found; Rapi-Fs dist may not be installed properly.\n";
  
  my $loc_assets_dir = join('/',$self->share_dir,'assets');
  -d $loc_assets_dir or die "assets dir ($loc_assets_dir) not found; Rapi-Fs dist may not be installed properly.\n";
  
  exists $self->filetree_params->{mounts} and die join('',
    "'mounts' param is configured in its own attr",
    "-- don't also suppy in 'filetree_params'"
  );
  
  return {
    'RapidApp' => {
      load_modules => {
        files => {
          class  => 'Rapi::Fs::Module::FileTree',
          params => { 
            %{ $self->filetree_params },
            mounts => $self->mounts 
          }
        }
      },
      local_assets_dir => $loc_assets_dir,
      default_favicon_url => '/assets/local/misc/static/folder_explore.ico'
    },
    'Plugin::RapidApp::TabGui' => {
      title              => (ref $self),
      right_footer       => join('','Generated by ',(ref $self),' v',$VERSION),      
      nav_title_iconcls  => 'icon-folder-explore',
      navtrees => [{
        module => '/files',
      }]  
    },
    'Controller::RapidApp::Template' => {
      include_paths => [ $tpl_dir ]
    },
  }
}

1;
