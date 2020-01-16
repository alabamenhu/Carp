# Carp

Carp is a module that lets you identify errors from the **caller** side, rather than from within
*callee* (this means if you call `foo` inside of `bar`, and `foo` carps, the error will appear
as coming from the line where `foo` was called, rather than from inside of `foo`.  This can be useful
when writing modules to identify the error as resulting from something that happened outside of the
sub where it is being called.
It is modeled after Perl’s C<Carp> module, although it doesn’t quite (yet) support
all of the same features.  Additional options will be enabled in the future.

## Usage

By default, Carp only imports a single routine, C<carp>.  You can add the others in with the
named arguments `:cuckle`, `:croak`, `:confess`, or for ease, you can use `:all`.  There are
two options that can be specified with positional parameters, `'block'` and `'ofun'`.

```raku
use Carp;                    # imports only carp
use Carp :cuckle;            # imports carp and cuckle
use Carp :croak, :confess;   # imports carp, croak, and confess
use Carp :X;                 # imports exceptions (useful in CATCH blocks)
use Carp :all                # imports carp, cuckle, croak, and confess
use Carp 'block';            # enable block-level status
use Carp 'ofun';             # use -Ofun optimization
use Carp :all, <block ofun>; # import/enable everything
```

To use, just call the routine, optionally with a message.

```raku
use Carp;
carp;   # output: Carped: something's wrong
        #           in block <foo> at <file> line <line>
        # (the values in <> will have useful information)

carp "foo";   # output: foo
              #           in block <foo> at <file> line <line>
              # (the values in <> will have useful information)

```
## Differences

The following table is a quick reference guide on the meaning:

|                | **Warns** | **Dies** |
| **No trace**   |   carp    |   croak  |
| **Backtrace**  |  cuckle   |  confess |

`carp` and `cuckle` will only warn (`CX-Warn`), and normally not interrupt your program flow.
`croak` and `confess` will die, and must be manually resumed if recovery is possible.
`carp` and `croak` will only output a single indicating where the issue occurred.
`cuckle` and `confess` will output a full backtrace.

## Options

- **`block`**
Because `carp` and `croak` provide a single line, it makes more sense to identify the sub or
method where the error happened, as otherwise reporting something as occurring in an unnamed
block isn’t very helpful.  So instead, the original line of the error is noted, but reported
as occurring inside of the most immediate sub/method.  The same behavior exists for `cuckle`
and `confess`, but after their *first* line of output in the trace, every block is reported.

- **`ofun`**
The names of the routines were inherited from Perl’s Carp module.  Since Raku can handle
Unicode no problem, there’s nothing wrong with a little bit of **O**(*fun*), right?  Enable
this, and instead of seeing the out "Croak:", you'll get a little frog saying it instead.
No other functionality is changed:

## Examples
![Regex::FuzzyToken for Raku](resources/logo.png)

```raku
use Carp :all;

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

foo;
```

The output of this is (with default options)

```
Carping inside foo
  in block <unit> at 00-sanity.t line 19
carping inside bar
  in sub foo at 00-sanity.t line 6
clucking inside bar
  in sub foo at 00-sanity.t line 7
  in sub foo at 00-sanity.t line 20
  in block <unit> at 00-sanity.t line 23
===SORRY!===
Croaking inside bar
  in sub foo at 00-sanity.t line 14
===RESUMING!===
===SORRY!===
Confessed:
  in sub bar at 00-sanity.t line 3
  in sub foo at 00-sanity.t line 20
  in block <unit> at 00-sanity.t line 23
===RESUMING!===
```

With `:ofun`, we get a funner (but equally useful) output:
```
🐟 . o O ( Carping inside foo )
  in block <unit> at 00-sanity.t line 19
🐟 . o O ( carping inside bar )
  in sub foo at 00-sanity.t line 6
🐔 . o O ( clucking inside bar )
  in sub foo at 00-sanity.t line 7
  in block <unit> at 00-sanity.t line 23
===SORRY!===
🐸 . o O ( Croaking inside bar )
  in sub foo at 00-sanity.t line 14
===RESUMING!===
===SORRY!===
🙏 . o O ( confession )
  in sub bar at 00-sanity.t line 3
  in sub foo at 00-sanity.t line 20
  in block <unit> at 00-sanity.t line 23
===RESUMING!===
```

## To do

Carp in Perl has quite a few options that could be implemented, and then some.

  - Creating settings at scope level (currently settings are global)
  - Formatter options
  - Excluded packages, either generally (like in Perl) or in each call.
  - Adjust default frames to skip (for example, using carp in a signatuers where clause results in the error unusefully being reported as from the ACCEPTS sub)
  - Verbose option (make croak act like confess, and carp like cluck)
  - Return proper values for the `.backtrace` method (creating a modified Backtrace isn't presently working well).
  - Implement warnings proper: throwing a CX::Warn currently dies, so `note` is used in the meantime.

# Licenses and Acknowledgements

All code is and documentation is licensed under the Artistic License 2.0, included with
the module.

The original Carp was created by Larry Wall and Andrew Main (Zefram).  Because of differences
between Perl and Raku, no code was ported directly.