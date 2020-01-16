my $BLOCK  = False;
my $PRETTY = False;

#`<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# For some reason, throwing a CX::Warn manually still dies.
# In Rakudo's source, 'warn' doesn't issue a typical Exception,
# but I'm not sure I want to add in NQP at the moment.
class CX::Carp is CX::Warn is export(:all, :X) {
  has $.carp;
  has %.frame;
  method new($carp, :$line, :$type, :$file, :$name) {
    self.bless(:$carp, :frame(:$line, :$type, :$file, :$name))
  }

  method message {
    if $PRETTY {
      "🐟 . o O ( {$!carp // 'carp'} )\n  in %!frame<type> %!frame<name> at %!frame<file> line %!frame<line>";
    } else {
      ($!carp // 'Carped:') ~ "\n  in %!frame<type> %!frame<name> at %!frame<file> line %!frame<line>";
    }
  }

  method backtrace {
    "" # keeps it from printing an inaccurate BT
    # I've not been able to correctly override this
  }
}

class X::Cluck is Exception is export(:all,:X) {
  has $.confession;
  has @.frames;
  has %.frame;
  method new($confession, :$line, :$type, :$file, :$name, :@frames) {
    self.bless(:$confession, :frame(:$line, :$type, :$file, :$name), :@frames)
  }

  method message {
    if $PRETTY {
      [~] "🙏 . o O ( {$!confession // 'confession'} )\n  in {%!frame<type>} {%!frame<name>} at {%!frame<file>} line {%!frame<line>}\n",
              @!frames>>.Str.join.chomp;
    } else {
      [~] ($!confession // 'Confessed:'),
              "\n  in {%!frame<type>} {%!frame<name>} at {%!frame<file>} line {%!frame<line>}\n",
              @!frames>>.Str.join.chomp;
    }
  }

  method backtrace { "" }
}
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


sub EXPORT (**@args) {
  for @args {
    when 'block' { $BLOCK  = True }
    when 'ofun'  { $PRETTY = True }
    when <cluck croak confess>.any { say "Carp: To use ‘$_’, include as a named parameter (use Carp :$_)"}
    default { say "Carp: Unknown option ‘$_’" }
  }
  %(
    # Must export this way because if no named arguments are used
    # then anything with just 'is export' won't be exported.
    '&carp' => sub carp($message?, --> True) {
      # Ignores backtrace creation (2 frames) and carp() (1 frame)
      my @frames = Backtrace.new(3).list;

      my $line = @frames.head.line; # line of error

      unless $BLOCK {
        # Rewind to sub/method level
        # todo: detect signatures and go beyond ACCEPT()
        @frames.shift;
        @frames.shift while @frames && @frames.head.code !~~ Routine;
      }

      # The special cases here are for top level and/or REPL
      my $type = @frames.head.code.^name.lc;
         $type = 'block' if $type eq 'nil';
      my $file = @frames.head.file    // $*PROGRAM-NAME;
      my $name = @frames.head.subname // '<unit>';

      # This line should work, but CX::Warn actually dies, so not the result we want.
      # CX::Carp.new($message, :$line, :$type, :$file, :$name).throw;
      # So instead, manually…
      if $PRETTY {
        note "🐟 . o O ( { $message// "carp" } )\n"
           ~ "  in $type $name at $file line $line";
      } else {
        note ($message // "Carped: something's wrong") ~ "\n"
                        ~ "  in $type $name at $file line $line";
      }

    }
  );
}


sub cluck($message?) is export(:cluck, :all) {
  # Ignores backtrace creation (2 frames) and cluck() (1 frame)
  my @frames = Backtrace.new(3).list;

  my $line = @frames.head.line; # line of error
  unless $BLOCK {
    # Rewind to sub/method level, if run out, it's top level
    @frames.shift;
    @frames.shift while @frames && @frames.head.code !~~ Routine;
  }

  my $type = @frames.head.code.^name.lc;
     $type = 'block' if $type eq 'nil';
  my $file = @frames.head.file // '<unknown-file>';
  my $name = @frames.head.subname // '<unit>';

  @frames.shift;

  if $PRETTY {
    note [~] "🐔 . o O ( { $message// "cluck" } )\n  in $type $name at $file line $line",
    ("\n  in {.code.^name.lc} {.subname} at {.file} line {.line}" for @frames[1..*]) if @frames > 0; # output should match "  in sub foo at bar.p6 line 0" format
  } else {
    note [~] ($message // "Cluck: something's wrong") ~
                   "\n  in $type $name at $file line $line\n",
                   @frames>>.Str.join.chomp;
  }
}






class X::Croak is Exception is export(:all,:X) {

  has $.ribbit;
  has %.frame;
  has $.pretty;

  method new($ribbit, :$line, :$type, :$file, :$name, :$*pretty = False) {
    self.bless(:$ribbit, :frame(:$line, :$type, :$file, :$name))
  }

  method message {
    if $!pretty {
      "🐸 . o O ( {$!ribbit // 'ribbit'} )\n  in {%!frame<type>} {%!frame<name>} at {%!frame<file>} line {%!frame<line>}";
    } else {
      ($!ribbit // 'Croaked:') ~ "\n  in {%!frame<type>} {%!frame<name>} at {%!frame<file>} line {%!frame<line>}";
    }
  }

  method backtrace {
    "" # keeps it from printing an inaccurate BT
    # I've not been able to correctly override this
  }
}

sub croak($message?) is export(:croak, :all) {
  # Grab a backtrace, ignoring the backtrace creation (2 frames) and the croak sub (1 frame)
  my @frames = Backtrace.new(3).list;

  my $line = @frames.head.line; # line of error
  unless $BLOCK {
    # Rewind to sub/method level, if run out, it's top level
    @frames.shift;
    @frames.shift while @frames && @frames.head.code !~~ Routine;
  }

  my $type = @frames.head.code.^name.lc;
     $type = 'block' if $type eq 'nil';
  my $file = @frames.head.file // '<unknown-file>';
  my $name = @frames.head.subname // '<unit>';

  X::Croak.new($message, :$line, :$type, :$file, :$name).throw;
}










class X::Confess is Exception is export(:all,:X) {
  has $.confession;
  has @.frames;
  has %.frame;
  method new($confession, :$line, :$type, :$file, :$name, :@frames) {
    self.bless(:$confession, :frame(:$line, :$type, :$file, :$name), :@frames)
  }

  method message {
    if $PRETTY {
      [~] "🙏 . o O ( {$!confession // 'confession'} )\n  in {%!frame<type>} {%!frame<name>} at {%!frame<file>} line {%!frame<line>}\n",
              @!frames>>.Str.join.chomp;
    } else {
      [~] ($!confession // 'Confessed:'),
              "\n  in {%!frame<type>} {%!frame<name>} at {%!frame<file>} line {%!frame<line>}\n",
              @!frames>>.Str.join.chomp;
    }
  }

  method backtrace { "" }
}

sub confess($message?) is export(:confess, :all) {

  # Grab a backtrace, ignoring the backtrace creation (2 frames) and the croak sub (1 frame)
  my @frames = Backtrace.new(3).list;

  my $line = @frames.head.line; # line of error
  unless $BLOCK {
    # Rewind to sub/method level, if run out, it's top level
    @frames.shift;
    @frames.shift while @frames && @frames.head.code !~~ Routine;
  }

  my $type = @frames.head.code.^name.lc;
  $type = 'block' if $type eq 'nil';
  my $file = @frames.head.file // '<unknown-file>';
  my $name = @frames.head.subname // '<unit>';

  @frames.shift; # removes top level that's been specially modified;
  X::Confess.new($message, :$line, :$type, :$file, :$name, :@frames).throw;
}