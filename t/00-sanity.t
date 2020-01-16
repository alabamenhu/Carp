use Carp :all;
use Test;

# Better test files to come.

sub xyz { confess "Confessing in XYX" }

sub bar {
  carp "carping inside bar";
  cluck "clucking inside bar";
  CATCH {
    $*ERR.say: "===SORRY!===";
    $*ERR.say: .message;
    $*ERR.say: "===RESUMING!===";
    .resume;
  }
  croak  "Croaking inside bar";
  xyz;
}

sub foo {
  carp "Carping inside foo";
  bar;
}

sub abc ($foo where {$_ > 2 || carp "Expected a value greater than 2"}) {

}

foo;
abc 1;

done-testing;
