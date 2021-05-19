####################################################################
#
#    This file was generated using Parse::Yapp version 1.21.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Parse::Pidl::IDL;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module Parse::Yapp::Driver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# Copyright © 1998, 1999, 2000, 2001, Francois Desarmenien.
# Copyright © 2017 William N. Braswell, Jr.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

# CORRELATION #py001: $VERSION must be changed in both Parse::Yapp & Parse::Yapp::Driver
$VERSION = '1.21';
$COMPATIBLE = '0.07';
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------




sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.21',
                                  yystates =>
[
	{#State 0
		DEFAULT => -1,
		GOTOS => {
			'idl' => 1
		}
	},
	{#State 1
		ACTIONS => {
			'' => 11,
			"include" => 3,
			"import" => 6,
			"importlib" => 8
		},
		DEFAULT => -98,
		GOTOS => {
			'include' => 9,
			'property_list' => 7,
			'import' => 5,
			'importlib' => 10,
			'interface' => 4,
			'coclass' => 2
		}
	},
	{#State 2
		DEFAULT => -3
	},
	{#State 3
		ACTIONS => {
			'TEXT' => 13
		},
		GOTOS => {
			'text' => 12,
			'commalist' => 14
		}
	},
	{#State 4
		DEFAULT => -2
	},
	{#State 5
		DEFAULT => -4
	},
	{#State 6
		ACTIONS => {
			'TEXT' => 13
		},
		GOTOS => {
			'text' => 12,
			'commalist' => 15
		}
	},
	{#State 7
		ACTIONS => {
			"[" => 18,
			"coclass" => 16,
			"interface" => 17
		}
	},
	{#State 8
		ACTIONS => {
			'TEXT' => 13
		},
		GOTOS => {
			'text' => 12,
			'commalist' => 19
		}
	},
	{#State 9
		DEFAULT => -5
	},
	{#State 10
		DEFAULT => -6
	},
	{#State 11
		DEFAULT => 0
	},
	{#State 12
		DEFAULT => -10
	},
	{#State 13
		DEFAULT => -129
	},
	{#State 14
		ACTIONS => {
			"," => 21,
			";" => 20
		}
	},
	{#State 15
		ACTIONS => {
			";" => 22,
			"," => 21
		}
	},
	{#State 16
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 23
		}
	},
	{#State 17
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 25
		}
	},
	{#State 18
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'property' => 28,
			'identifier' => 27,
			'properties' => 26
		}
	},
	{#State 19
		ACTIONS => {
			";" => 29,
			"," => 21
		}
	},
	{#State 20
		DEFAULT => -8
	},
	{#State 21
		ACTIONS => {
			'TEXT' => 13
		},
		GOTOS => {
			'text' => 30
		}
	},
	{#State 22
		DEFAULT => -7
	},
	{#State 23
		ACTIONS => {
			"{" => 31
		}
	},
	{#State 24
		DEFAULT => -125
	},
	{#State 25
		ACTIONS => {
			":" => 32
		},
		DEFAULT => -16,
		GOTOS => {
			'base_interface' => 33
		}
	},
	{#State 26
		ACTIONS => {
			"]" => 34,
			"," => 35
		}
	},
	{#State 27
		ACTIONS => {
			"(" => 36
		},
		DEFAULT => -102
	},
	{#State 28
		DEFAULT => -100
	},
	{#State 29
		DEFAULT => -9
	},
	{#State 30
		DEFAULT => -11
	},
	{#State 31
		DEFAULT => -13,
		GOTOS => {
			'interface_names' => 37
		}
	},
	{#State 32
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 38
		}
	},
	{#State 33
		ACTIONS => {
			"{" => 39
		}
	},
	{#State 34
		DEFAULT => -99
	},
	{#State 35
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'property' => 40,
			'identifier' => 27
		}
	},
	{#State 36
		ACTIONS => {
			'IDENTIFIER' => 24,
			'TEXT' => 13,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'text' => 42,
			'anytext' => 41,
			'identifier' => 43,
			'commalisttext' => 45,
			'constant' => 44
		}
	},
	{#State 37
		ACTIONS => {
			"}" => 47,
			"interface" => 48
		}
	},
	{#State 38
		DEFAULT => -17
	},
	{#State 39
		ACTIONS => {
			"typedef" => 51,
			"enum" => 63,
			"union" => 50,
			"const" => 49,
			"struct" => 68,
			"bitmap" => 53,
			"declare" => 54
		},
		DEFAULT => -98,
		GOTOS => {
			'typedecl' => 67,
			'property_list' => 55,
			'enum' => 56,
			'function' => 57,
			'definition' => 58,
			'declare' => 59,
			'const' => 60,
			'struct' => 61,
			'definitions' => 62,
			'bitmap' => 64,
			'union' => 52,
			'typedef' => 66,
			'usertype' => 65
		}
	},
	{#State 40
		DEFAULT => -101
	},
	{#State 41
		ACTIONS => {
			"/" => 70,
			"(" => 71,
			"<" => 72,
			"|" => 69,
			"~" => 74,
			"=" => 75,
			":" => 73,
			"." => 78,
			"-" => 77,
			">" => 76,
			"+" => 82,
			"{" => 83,
			"?" => 81,
			"*" => 80,
			"&" => 79
		},
		DEFAULT => -104
	},
	{#State 42
		DEFAULT => -109
	},
	{#State 43
		DEFAULT => -107
	},
	{#State 44
		DEFAULT => -108
	},
	{#State 45
		ACTIONS => {
			")" => 85,
			"," => 84
		}
	},
	{#State 46
		DEFAULT => -128
	},
	{#State 47
		ACTIONS => {
			";" => 87
		},
		DEFAULT => -130,
		GOTOS => {
			'optional_semicolon' => 86
		}
	},
	{#State 48
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 88
		}
	},
	{#State 49
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 89
		}
	},
	{#State 50
		ACTIONS => {
			'IDENTIFIER' => 90
		},
		DEFAULT => -127,
		GOTOS => {
			'optional_identifier' => 91
		}
	},
	{#State 51
		DEFAULT => -98,
		GOTOS => {
			'property_list' => 92
		}
	},
	{#State 52
		DEFAULT => -43
	},
	{#State 53
		ACTIONS => {
			'IDENTIFIER' => 90
		},
		DEFAULT => -127,
		GOTOS => {
			'optional_identifier' => 93
		}
	},
	{#State 54
		DEFAULT => -98,
		GOTOS => {
			'property_list' => 94
		}
	},
	{#State 55
		ACTIONS => {
			"signed" => 101,
			"bitmap" => 53,
			'void' => 98,
			"struct" => 68,
			'IDENTIFIER' => 24,
			"union" => 50,
			"unsigned" => 100,
			"enum" => 63,
			"[" => 18
		},
		GOTOS => {
			'usertype' => 99,
			'union' => 52,
			'existingtype' => 95,
			'bitmap' => 64,
			'enum' => 56,
			'sign' => 102,
			'struct' => 61,
			'identifier' => 97,
			'type' => 96
		}
	},
	{#State 56
		DEFAULT => -44
	},
	{#State 57
		DEFAULT => -20
	},
	{#State 58
		DEFAULT => -18
	},
	{#State 59
		DEFAULT => -23
	},
	{#State 60
		DEFAULT => -21
	},
	{#State 61
		DEFAULT => -42
	},
	{#State 62
		ACTIONS => {
			"}" => 104,
			"enum" => 63,
			"union" => 50,
			"const" => 49,
			"typedef" => 51,
			"struct" => 68,
			"declare" => 54,
			"bitmap" => 53
		},
		DEFAULT => -98,
		GOTOS => {
			'union' => 52,
			'bitmap' => 64,
			'typedef' => 66,
			'usertype' => 65,
			'typedecl' => 67,
			'enum' => 56,
			'function' => 57,
			'property_list' => 55,
			'declare' => 59,
			'definition' => 103,
			'struct' => 61,
			'const' => 60
		}
	},
	{#State 63
		ACTIONS => {
			'IDENTIFIER' => 90
		},
		DEFAULT => -127,
		GOTOS => {
			'optional_identifier' => 105
		}
	},
	{#State 64
		DEFAULT => -45
	},
	{#State 65
		ACTIONS => {
			";" => 106
		}
	},
	{#State 66
		DEFAULT => -22
	},
	{#State 67
		DEFAULT => -24
	},
	{#State 68
		ACTIONS => {
			'IDENTIFIER' => 90
		},
		DEFAULT => -127,
		GOTOS => {
			'optional_identifier' => 107
		}
	},
	{#State 69
		ACTIONS => {
			'IDENTIFIER' => 24,
			'TEXT' => 13,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'constant' => 44,
			'identifier' => 43,
			'anytext' => 108,
			'text' => 42
		}
	},
	{#State 70
		ACTIONS => {
			'CONSTANT' => 46,
			'IDENTIFIER' => 24,
			'TEXT' => 13
		},
		DEFAULT => -106,
		GOTOS => {
			'identifier' => 43,
			'anytext' => 109,
			'text' => 42,
			'constant' => 44
		}
	},
	{#State 71
		ACTIONS => {
			'CONSTANT' => 46,
			'TEXT' => 13,
			'IDENTIFIER' => 24
		},
		DEFAULT => -106,
		GOTOS => {
			'commalisttext' => 110,
			'constant' => 44,
			'text' => 42,
			'anytext' => 41,
			'identifier' => 43
		}
	},
	{#State 72
		ACTIONS => {
			'CONSTANT' => 46,
			'TEXT' => 13,
			'IDENTIFIER' => 24
		},
		DEFAULT => -106,
		GOTOS => {
			'anytext' => 111,
			'text' => 42,
			'identifier' => 43,
			'constant' => 44
		}
	},
	{#State 73
		ACTIONS => {
			'TEXT' => 13,
			'IDENTIFIER' => 24,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'constant' => 44,
			'anytext' => 112,
			'text' => 42,
			'identifier' => 43
		}
	},
	{#State 74
		ACTIONS => {
			'CONSTANT' => 46,
			'TEXT' => 13,
			'IDENTIFIER' => 24
		},
		DEFAULT => -106,
		GOTOS => {
			'constant' => 44,
			'anytext' => 113,
			'text' => 42,
			'identifier' => 43
		}
	},
	{#State 75
		ACTIONS => {
			'IDENTIFIER' => 24,
			'TEXT' => 13,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'text' => 42,
			'anytext' => 114,
			'identifier' => 43,
			'constant' => 44
		}
	},
	{#State 76
		ACTIONS => {
			'IDENTIFIER' => 24,
			'TEXT' => 13,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'constant' => 44,
			'identifier' => 43,
			'anytext' => 115,
			'text' => 42
		}
	},
	{#State 77
		ACTIONS => {
			'TEXT' => 13,
			'IDENTIFIER' => 24,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'constant' => 44,
			'identifier' => 43,
			'text' => 42,
			'anytext' => 116
		}
	},
	{#State 78
		ACTIONS => {
			'CONSTANT' => 46,
			'IDENTIFIER' => 24,
			'TEXT' => 13
		},
		DEFAULT => -106,
		GOTOS => {
			'identifier' => 43,
			'anytext' => 117,
			'text' => 42,
			'constant' => 44
		}
	},
	{#State 79
		ACTIONS => {
			'CONSTANT' => 46,
			'IDENTIFIER' => 24,
			'TEXT' => 13
		},
		DEFAULT => -106,
		GOTOS => {
			'identifier' => 43,
			'text' => 42,
			'anytext' => 118,
			'constant' => 44
		}
	},
	{#State 80
		ACTIONS => {
			'CONSTANT' => 46,
			'TEXT' => 13,
			'IDENTIFIER' => 24
		},
		DEFAULT => -106,
		GOTOS => {
			'constant' => 44,
			'text' => 42,
			'anytext' => 119,
			'identifier' => 43
		}
	},
	{#State 81
		ACTIONS => {
			'TEXT' => 13,
			'IDENTIFIER' => 24,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'identifier' => 43,
			'text' => 42,
			'anytext' => 120,
			'constant' => 44
		}
	},
	{#State 82
		ACTIONS => {
			'CONSTANT' => 46,
			'IDENTIFIER' => 24,
			'TEXT' => 13
		},
		DEFAULT => -106,
		GOTOS => {
			'text' => 42,
			'anytext' => 121,
			'identifier' => 43,
			'constant' => 44
		}
	},
	{#State 83
		ACTIONS => {
			'TEXT' => 13,
			'IDENTIFIER' => 24,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'constant' => 44,
			'commalisttext' => 122,
			'identifier' => 43,
			'text' => 42,
			'anytext' => 41
		}
	},
	{#State 84
		ACTIONS => {
			'CONSTANT' => 46,
			'TEXT' => 13,
			'IDENTIFIER' => 24
		},
		DEFAULT => -106,
		GOTOS => {
			'identifier' => 43,
			'text' => 42,
			'anytext' => 123,
			'constant' => 44
		}
	},
	{#State 85
		DEFAULT => -103
	},
	{#State 86
		DEFAULT => -12
	},
	{#State 87
		DEFAULT => -131
	},
	{#State 88
		ACTIONS => {
			";" => 124
		}
	},
	{#State 89
		DEFAULT => -87,
		GOTOS => {
			'pointers' => 125
		}
	},
	{#State 90
		DEFAULT => -126
	},
	{#State 91
		ACTIONS => {
			"{" => 127
		},
		DEFAULT => -83,
		GOTOS => {
			'union_body' => 128,
			'opt_union_body' => 126
		}
	},
	{#State 92
		ACTIONS => {
			"signed" => 101,
			"struct" => 68,
			"bitmap" => 53,
			'void' => 98,
			'IDENTIFIER' => 24,
			"enum" => 63,
			"[" => 18,
			"union" => 50,
			"unsigned" => 100
		},
		DEFAULT => -49,
		GOTOS => {
			'sign' => 102,
			'enum' => 56,
			'type' => 129,
			'identifier' => 97,
			'struct' => 61,
			'bitmap' => 64,
			'existingtype' => 130,
			'union' => 52,
			'usertype' => 99
		}
	},
	{#State 93
		ACTIONS => {
			"{" => 131
		},
		DEFAULT => -64,
		GOTOS => {
			'opt_bitmap_body' => 133,
			'bitmap_body' => 132
		}
	},
	{#State 94
		ACTIONS => {
			"bitmap" => 138,
			"union" => 140,
			"[" => 18,
			"enum" => 134
		},
		GOTOS => {
			'decl_bitmap' => 139,
			'decl_enum' => 137,
			'decl_type' => 135,
			'decl_union' => 136
		}
	},
	{#State 95
		DEFAULT => -53
	},
	{#State 96
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 141
		}
	},
	{#State 97
		DEFAULT => -51
	},
	{#State 98
		DEFAULT => -54
	},
	{#State 99
		DEFAULT => -52
	},
	{#State 100
		DEFAULT => -48
	},
	{#State 101
		DEFAULT => -47
	},
	{#State 102
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 142
		}
	},
	{#State 103
		DEFAULT => -19
	},
	{#State 104
		ACTIONS => {
			";" => 87
		},
		DEFAULT => -130,
		GOTOS => {
			'optional_semicolon' => 143
		}
	},
	{#State 105
		ACTIONS => {
			"{" => 146
		},
		DEFAULT => -56,
		GOTOS => {
			'enum_body' => 144,
			'opt_enum_body' => 145
		}
	},
	{#State 106
		DEFAULT => -46
	},
	{#State 107
		ACTIONS => {
			"{" => 148
		},
		DEFAULT => -73,
		GOTOS => {
			'struct_body' => 149,
			'opt_struct_body' => 147
		}
	},
	{#State 108
		ACTIONS => {
			"<" => 72,
			":" => 73,
			"=" => 75,
			"~" => 74,
			"?" => 81,
			"{" => 83
		},
		DEFAULT => -115
	},
	{#State 109
		ACTIONS => {
			"<" => 72,
			"~" => 74,
			"=" => 75,
			":" => 73,
			"{" => 83,
			"?" => 81
		},
		DEFAULT => -117
	},
	{#State 110
		ACTIONS => {
			"," => 84,
			")" => 150
		}
	},
	{#State 111
		ACTIONS => {
			"{" => 83,
			"+" => 82,
			"&" => 79,
			"*" => 80,
			"?" => 81,
			"." => 78,
			">" => 76,
			"-" => 77,
			"~" => 74,
			"=" => 75,
			":" => 73,
			"|" => 69,
			"<" => 72,
			"/" => 70,
			"(" => 71
		},
		DEFAULT => -114
	},
	{#State 112
		ACTIONS => {
			":" => 73,
			"~" => 74,
			"=" => 75,
			"<" => 72,
			"/" => 70,
			"(" => 71,
			"|" => 69,
			"?" => 81,
			"&" => 79,
			"*" => 80,
			"{" => 83,
			"+" => 82,
			"-" => 77,
			">" => 76,
			"." => 78
		},
		DEFAULT => -119
	},
	{#State 113
		ACTIONS => {
			"." => 78,
			">" => 76,
			"-" => 77,
			"{" => 83,
			"+" => 82,
			"*" => 80,
			"&" => 79,
			"?" => 81,
			"|" => 69,
			"(" => 71,
			"<" => 72,
			"/" => 70,
			"=" => 75,
			"~" => 74,
			":" => 73
		},
		DEFAULT => -122
	},
	{#State 114
		ACTIONS => {
			"&" => 79,
			"*" => 80,
			"?" => 81,
			"+" => 82,
			"{" => 83,
			">" => 76,
			"-" => 77,
			"." => 78,
			":" => 73,
			"~" => 74,
			"=" => 75,
			"|" => 69,
			"<" => 72,
			"/" => 70,
			"(" => 71
		},
		DEFAULT => -120
	},
	{#State 115
		ACTIONS => {
			"<" => 72,
			":" => 73,
			"=" => 75,
			"~" => 74,
			"?" => 81,
			"{" => 83
		},
		DEFAULT => -113
	},
	{#State 116
		ACTIONS => {
			"{" => 83,
			"?" => 81,
			"<" => 72,
			"~" => 74,
			"=" => 75,
			":" => 73
		},
		DEFAULT => -110
	},
	{#State 117
		ACTIONS => {
			"{" => 83,
			"?" => 81,
			"<" => 72,
			"~" => 74,
			"=" => 75,
			":" => 73
		},
		DEFAULT => -111
	},
	{#State 118
		ACTIONS => {
			"?" => 81,
			"{" => 83,
			"<" => 72,
			":" => 73,
			"~" => 74,
			"=" => 75
		},
		DEFAULT => -116
	},
	{#State 119
		ACTIONS => {
			"?" => 81,
			"{" => 83,
			":" => 73,
			"~" => 74,
			"=" => 75,
			"<" => 72
		},
		DEFAULT => -112
	},
	{#State 120
		ACTIONS => {
			"-" => 77,
			">" => 76,
			"." => 78,
			"?" => 81,
			"&" => 79,
			"*" => 80,
			"+" => 82,
			"{" => 83,
			"<" => 72,
			"(" => 71,
			"/" => 70,
			"|" => 69,
			":" => 73,
			"=" => 75,
			"~" => 74
		},
		DEFAULT => -118
	},
	{#State 121
		ACTIONS => {
			"?" => 81,
			"{" => 83,
			":" => 73,
			"~" => 74,
			"=" => 75,
			"<" => 72
		},
		DEFAULT => -121
	},
	{#State 122
		ACTIONS => {
			"}" => 151,
			"," => 84
		}
	},
	{#State 123
		ACTIONS => {
			"<" => 72,
			"(" => 71,
			"/" => 70,
			"|" => 69,
			"=" => 75,
			"~" => 74,
			":" => 73,
			"." => 78,
			"-" => 77,
			">" => 76,
			"+" => 82,
			"{" => 83,
			"?" => 81,
			"&" => 79,
			"*" => 80
		},
		DEFAULT => -105
	},
	{#State 124
		DEFAULT => -14
	},
	{#State 125
		ACTIONS => {
			'IDENTIFIER' => 24,
			"*" => 153
		},
		GOTOS => {
			'identifier' => 152
		}
	},
	{#State 126
		DEFAULT => -85
	},
	{#State 127
		DEFAULT => -80,
		GOTOS => {
			'union_elements' => 154
		}
	},
	{#State 128
		DEFAULT => -84
	},
	{#State 129
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 155
		}
	},
	{#State 130
		ACTIONS => {
			"*" => 160,
			"(" => 157,
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 158,
			'declarator' => 156,
			'direct_declarator' => 159
		}
	},
	{#State 131
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		DEFAULT => -69,
		GOTOS => {
			'opt_bitmap_elements' => 161,
			'identifier' => 164,
			'bitmap_elements' => 163,
			'bitmap_element' => 162
		}
	},
	{#State 132
		DEFAULT => -65
	},
	{#State 133
		DEFAULT => -66
	},
	{#State 134
		DEFAULT => -32
	},
	{#State 135
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 165
		}
	},
	{#State 136
		DEFAULT => -31
	},
	{#State 137
		DEFAULT => -29
	},
	{#State 138
		DEFAULT => -33
	},
	{#State 139
		DEFAULT => -30
	},
	{#State 140
		DEFAULT => -34
	},
	{#State 141
		ACTIONS => {
			"(" => 166
		}
	},
	{#State 142
		DEFAULT => -50
	},
	{#State 143
		DEFAULT => -15
	},
	{#State 144
		DEFAULT => -57
	},
	{#State 145
		DEFAULT => -58
	},
	{#State 146
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'enum_element' => 168,
			'enum_elements' => 167,
			'identifier' => 169
		}
	},
	{#State 147
		DEFAULT => -75
	},
	{#State 148
		DEFAULT => -89,
		GOTOS => {
			'element_list1' => 170
		}
	},
	{#State 149
		DEFAULT => -74
	},
	{#State 150
		ACTIONS => {
			'TEXT' => 13,
			'IDENTIFIER' => 24,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'anytext' => 171,
			'text' => 42,
			'identifier' => 43,
			'constant' => 44
		}
	},
	{#State 151
		ACTIONS => {
			'CONSTANT' => 46,
			'TEXT' => 13,
			'IDENTIFIER' => 24
		},
		DEFAULT => -106,
		GOTOS => {
			'text' => 42,
			'anytext' => 172,
			'identifier' => 43,
			'constant' => 44
		}
	},
	{#State 152
		ACTIONS => {
			"[" => 173,
			"=" => 174
		},
		GOTOS => {
			'array_len' => 175
		}
	},
	{#State 153
		DEFAULT => -88
	},
	{#State 154
		ACTIONS => {
			"}" => 178
		},
		DEFAULT => -98,
		GOTOS => {
			'optional_base_element' => 176,
			'property_list' => 177
		}
	},
	{#State 155
		ACTIONS => {
			"[" => 173
		},
		DEFAULT => -95,
		GOTOS => {
			'array_len' => 179
		}
	},
	{#State 156
		ACTIONS => {
			";" => 180
		}
	},
	{#State 157
		ACTIONS => {
			'IDENTIFIER' => 24,
			"(" => 157,
			"*" => 160
		},
		GOTOS => {
			'declarator' => 181,
			'direct_declarator' => 159,
			'identifier' => 158
		}
	},
	{#State 158
		DEFAULT => -39
	},
	{#State 159
		ACTIONS => {
			"[" => 182
		},
		DEFAULT => -37
	},
	{#State 160
		ACTIONS => {
			"(" => 157,
			'IDENTIFIER' => 24,
			"*" => 160
		},
		GOTOS => {
			'identifier' => 158,
			'direct_declarator' => 159,
			'declarator' => 183
		}
	},
	{#State 161
		ACTIONS => {
			"}" => 184
		}
	},
	{#State 162
		DEFAULT => -67
	},
	{#State 163
		ACTIONS => {
			"," => 185
		},
		DEFAULT => -70
	},
	{#State 164
		ACTIONS => {
			"=" => 186
		}
	},
	{#State 165
		ACTIONS => {
			";" => 187
		}
	},
	{#State 166
		ACTIONS => {
			"," => -91,
			")" => -91,
			"void" => 190
		},
		DEFAULT => -98,
		GOTOS => {
			'element_list2' => 191,
			'base_element' => 188,
			'property_list' => 189
		}
	},
	{#State 167
		ACTIONS => {
			"}" => 193,
			"," => 192
		}
	},
	{#State 168
		DEFAULT => -59
	},
	{#State 169
		ACTIONS => {
			"=" => 194
		},
		DEFAULT => -61
	},
	{#State 170
		ACTIONS => {
			"}" => 196
		},
		DEFAULT => -98,
		GOTOS => {
			'base_element' => 195,
			'property_list' => 189
		}
	},
	{#State 171
		ACTIONS => {
			"?" => 81,
			"{" => 83,
			"<" => 72,
			":" => 73,
			"~" => 74,
			"=" => 75
		},
		DEFAULT => -123
	},
	{#State 172
		ACTIONS => {
			":" => 73,
			"~" => 74,
			"=" => 75,
			"|" => 69,
			"/" => 70,
			"<" => 72,
			"(" => 71,
			"*" => 80,
			"&" => 79,
			"?" => 81,
			"+" => 82,
			"{" => 83,
			">" => 76,
			"-" => 77,
			"." => 78
		},
		DEFAULT => -124
	},
	{#State 173
		ACTIONS => {
			'CONSTANT' => 46,
			"]" => 197,
			'TEXT' => 13,
			'IDENTIFIER' => 24
		},
		DEFAULT => -106,
		GOTOS => {
			'constant' => 44,
			'identifier' => 43,
			'text' => 42,
			'anytext' => 198
		}
	},
	{#State 174
		ACTIONS => {
			'TEXT' => 13,
			'IDENTIFIER' => 24,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'constant' => 44,
			'identifier' => 43,
			'text' => 42,
			'anytext' => 199
		}
	},
	{#State 175
		ACTIONS => {
			"=" => 200
		}
	},
	{#State 176
		DEFAULT => -81
	},
	{#State 177
		ACTIONS => {
			"[" => 18
		},
		DEFAULT => -98,
		GOTOS => {
			'base_or_empty' => 202,
			'base_element' => 203,
			'property_list' => 204,
			'empty_element' => 201
		}
	},
	{#State 178
		DEFAULT => -82
	},
	{#State 179
		ACTIONS => {
			";" => 205
		}
	},
	{#State 180
		DEFAULT => -36
	},
	{#State 181
		ACTIONS => {
			")" => 206
		}
	},
	{#State 182
		ACTIONS => {
			'CONSTANT' => 46,
			'IDENTIFIER' => 24,
			'TEXT' => 13
		},
		DEFAULT => -106,
		GOTOS => {
			'constant' => 44,
			'anytext' => 207,
			'text' => 42,
			'identifier' => 43
		}
	},
	{#State 183
		DEFAULT => -38
	},
	{#State 184
		DEFAULT => -63
	},
	{#State 185
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 164,
			'bitmap_element' => 208
		}
	},
	{#State 186
		ACTIONS => {
			'TEXT' => 13,
			'IDENTIFIER' => 24,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'anytext' => 209,
			'text' => 42,
			'identifier' => 43,
			'constant' => 44
		}
	},
	{#State 187
		DEFAULT => -28
	},
	{#State 188
		DEFAULT => -93
	},
	{#State 189
		ACTIONS => {
			'IDENTIFIER' => 24,
			"enum" => 63,
			"[" => 18,
			"unsigned" => 100,
			"union" => 50,
			"signed" => 101,
			"struct" => 68,
			'void' => 98,
			"bitmap" => 53
		},
		DEFAULT => -49,
		GOTOS => {
			'enum' => 56,
			'sign' => 102,
			'type' => 210,
			'identifier' => 97,
			'struct' => 61,
			'usertype' => 99,
			'existingtype' => 95,
			'bitmap' => 64,
			'union' => 52
		}
	},
	{#State 190
		DEFAULT => -92
	},
	{#State 191
		ACTIONS => {
			"," => 211,
			")" => 212
		}
	},
	{#State 192
		ACTIONS => {
			'IDENTIFIER' => 24
		},
		GOTOS => {
			'identifier' => 169,
			'enum_element' => 213
		}
	},
	{#State 193
		DEFAULT => -55
	},
	{#State 194
		ACTIONS => {
			'CONSTANT' => 46,
			'IDENTIFIER' => 24,
			'TEXT' => 13
		},
		DEFAULT => -106,
		GOTOS => {
			'constant' => 44,
			'identifier' => 43,
			'text' => 42,
			'anytext' => 214
		}
	},
	{#State 195
		ACTIONS => {
			";" => 215
		}
	},
	{#State 196
		DEFAULT => -72
	},
	{#State 197
		ACTIONS => {
			"[" => 173
		},
		DEFAULT => -95,
		GOTOS => {
			'array_len' => 216
		}
	},
	{#State 198
		ACTIONS => {
			"?" => 81,
			"&" => 79,
			"*" => 80,
			"{" => 83,
			"+" => 82,
			"]" => 217,
			"-" => 77,
			">" => 76,
			"." => 78,
			":" => 73,
			"=" => 75,
			"~" => 74,
			"(" => 71,
			"/" => 70,
			"<" => 72,
			"|" => 69
		}
	},
	{#State 199
		ACTIONS => {
			"~" => 74,
			"=" => 75,
			":" => 73,
			";" => 218,
			"|" => 69,
			"<" => 72,
			"/" => 70,
			"(" => 71,
			"{" => 83,
			"+" => 82,
			"&" => 79,
			"*" => 80,
			"?" => 81,
			"." => 78,
			">" => 76,
			"-" => 77
		}
	},
	{#State 200
		ACTIONS => {
			'TEXT' => 13,
			'IDENTIFIER' => 24,
			'CONSTANT' => 46
		},
		DEFAULT => -106,
		GOTOS => {
			'identifier' => 43,
			'anytext' => 219,
			'text' => 42,
			'constant' => 44
		}
	},
	{#State 201
		DEFAULT => -78
	},
	{#State 202
		DEFAULT => -79
	},
	{#State 203
		ACTIONS => {
			";" => 220
		}
	},
	{#State 204
		ACTIONS => {
			'IDENTIFIER' => 24,
			";" => 221,
			"union" => 50,
			"unsigned" => 100,
			"[" => 18,
			"enum" => 63,
			"signed" => 101,
			"bitmap" => 53,
			'void' => 98,
			"struct" => 68
		},
		DEFAULT => -49,
		GOTOS => {
			'enum' => 56,
			'sign' => 102,
			'struct' => 61,
			'type' => 210,
			'identifier' => 97,
			'usertype' => 99,
			'union' => 52,
			'existingtype' => 95,
			'bitmap' => 64
		}
	},
	{#State 205
		DEFAULT => -35
	},
	{#State 206
		DEFAULT => -40
	},
	{#State 207
		ACTIONS => {
			"]" => 222,
			"+" => 82,
			"{" => 83,
			"&" => 79,
			"*" => 80,
			"?" => 81,
			"." => 78,
			">" => 76,
			"-" => 77,
			"~" => 74,
			"=" => 75,
			":" => 73,
			"|" => 69,
			"/" => 70,
			"<" => 72,
			"(" => 71
		}
	},
	{#State 208
		DEFAULT => -68
	},
	{#State 209
		ACTIONS => {
			">" => 76,
			"-" => 77,
			"." => 78,
			"*" => 80,
			"&" => 79,
			"?" => 81,
			"+" => 82,
			"{" => 83,
			"|" => 69,
			"<" => 72,
			"(" => 71,
			"/" => 70,
			":" => 73,
			"=" => 75,
			"~" => 74
		},
		DEFAULT => -71
	},
	{#State 210
		DEFAULT => -87,
		GOTOS => {
			'pointers' => 223
		}
	},
	{#State 211
		DEFAULT => -98,
		GOTOS => {
			'base_element' => 224,
			'property_list' => 189
		}
	},
	{#State 212
		ACTIONS => {
			";" => 225
		}
	},
	{#State 213
		DEFAULT => -60
	},
	{#State 214
		ACTIONS => {
			"|" => 69,
			"(" => 71,
			"<" => 72,
			"/" => 70,
			":" => 73,
			"=" => 75,
			"~" => 74,
			">" => 76,
			"-" => 77,
			"." => 78,
			"*" => 80,
			"&" => 79,
			"?" => 81,
			"{" => 83,
			"+" => 82
		},
		DEFAULT => -62
	},
	{#State 215
		DEFAULT => -90
	},
	{#State 216
		DEFAULT => -96
	},
	{#State 217
		ACTIONS => {
			"[" => 173
		},
		DEFAULT => -95,
		GOTOS => {
			'array_len' => 226
		}
	},
	{#State 218
		DEFAULT => -25
	},
	{#State 219
		ACTIONS => {
			"?" => 81,
			"*" => 80,
			"&" => 79,
			"+" => 82,
			"{" => 83,
			"-" => 77,
			">" => 76,
			"." => 78,
			";" => 227,
			":" => 73,
			"~" => 74,
			"=" => 75,
			"<" => 72,
			"/" => 70,
			"(" => 71,
			"|" => 69
		}
	},
	{#State 220
		DEFAULT => -77
	},
	{#State 221
		DEFAULT => -76
	},
	{#State 222
		DEFAULT => -41
	},
	{#State 223
		ACTIONS => {
			'IDENTIFIER' => 24,
			"*" => 153
		},
		GOTOS => {
			'identifier' => 228
		}
	},
	{#State 224
		DEFAULT => -94
	},
	{#State 225
		DEFAULT => -27
	},
	{#State 226
		DEFAULT => -97
	},
	{#State 227
		DEFAULT => -26
	},
	{#State 228
		ACTIONS => {
			"[" => 173
		},
		DEFAULT => -95,
		GOTOS => {
			'array_len' => 229
		}
	},
	{#State 229
		DEFAULT => -86
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'idl', 0, undef
	],
	[#Rule 2
		 'idl', 2,
sub
#line 19 "pidl/idl.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 3
		 'idl', 2,
sub
#line 20 "pidl/idl.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 4
		 'idl', 2,
sub
#line 21 "pidl/idl.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 5
		 'idl', 2,
sub
#line 22 "pidl/idl.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 6
		 'idl', 2,
sub
#line 23 "pidl/idl.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 7
		 'import', 3,
sub
#line 26 "pidl/idl.yp"
{{
			"TYPE" => "IMPORT", 
			"PATHS" => $_[2],
		   "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		   "LINE" => $_[0]->YYData->{LINE}
		}}
	],
	[#Rule 8
		 'include', 3,
sub
#line 33 "pidl/idl.yp"
{{ 
			"TYPE" => "INCLUDE", 
			"PATHS" => $_[2],
		   "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		   "LINE" => $_[0]->YYData->{LINE}
		}}
	],
	[#Rule 9
		 'importlib', 3,
sub
#line 40 "pidl/idl.yp"
{{ 
			"TYPE" => "IMPORTLIB", 
			"PATHS" => $_[2],
		   "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		   "LINE" => $_[0]->YYData->{LINE}
		}}
	],
	[#Rule 10
		 'commalist', 1,
sub
#line 49 "pidl/idl.yp"
{ [ $_[1] ] }
	],
	[#Rule 11
		 'commalist', 3,
sub
#line 50 "pidl/idl.yp"
{ push(@{$_[1]}, $_[3]); $_[1] }
	],
	[#Rule 12
		 'coclass', 7,
sub
#line 54 "pidl/idl.yp"
{{
               "TYPE" => "COCLASS", 
	       "PROPERTIES" => $_[1],
	       "NAME" => $_[3],
	       "DATA" => $_[5],
		   "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		   "LINE" => $_[0]->YYData->{LINE},
          }}
	],
	[#Rule 13
		 'interface_names', 0, undef
	],
	[#Rule 14
		 'interface_names', 4,
sub
#line 66 "pidl/idl.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 15
		 'interface', 8,
sub
#line 70 "pidl/idl.yp"
{{
               "TYPE" => "INTERFACE", 
	       "PROPERTIES" => $_[1],
	       "NAME" => $_[3],
	       "BASE" => $_[4],
	       "DATA" => $_[6],
		   "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		   "LINE" => $_[0]->YYData->{LINE},
          }}
	],
	[#Rule 16
		 'base_interface', 0, undef
	],
	[#Rule 17
		 'base_interface', 2,
sub
#line 83 "pidl/idl.yp"
{ $_[2] }
	],
	[#Rule 18
		 'definitions', 1,
sub
#line 87 "pidl/idl.yp"
{ [ $_[1] ] }
	],
	[#Rule 19
		 'definitions', 2,
sub
#line 88 "pidl/idl.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 20
		 'definition', 1, undef
	],
	[#Rule 21
		 'definition', 1, undef
	],
	[#Rule 22
		 'definition', 1, undef
	],
	[#Rule 23
		 'definition', 1, undef
	],
	[#Rule 24
		 'definition', 1, undef
	],
	[#Rule 25
		 'const', 7,
sub
#line 96 "pidl/idl.yp"
{{
                     "TYPE"  => "CONST", 
		     "DTYPE"  => $_[2],
			 "POINTERS" => $_[3],
		     "NAME"  => $_[4],
		     "VALUE" => $_[6],
		     "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		     "LINE" => $_[0]->YYData->{LINE},
        }}
	],
	[#Rule 26
		 'const', 8,
sub
#line 106 "pidl/idl.yp"
{{
                     "TYPE"  => "CONST", 
		     "DTYPE"  => $_[2],
			 "POINTERS" => $_[3],
		     "NAME"  => $_[4],
		     "ARRAY_LEN" => $_[5],
		     "VALUE" => $_[7],
		     "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		     "LINE" => $_[0]->YYData->{LINE},
        }}
	],
	[#Rule 27
		 'function', 7,
sub
#line 120 "pidl/idl.yp"
{{
		"TYPE" => "FUNCTION",
		"NAME" => $_[3],
		"RETURN_TYPE" => $_[2],
		"PROPERTIES" => $_[1],
		"ELEMENTS" => $_[5],
		"FILE" => $_[0]->YYData->{INPUT_FILENAME},
		"LINE" => $_[0]->YYData->{LINE},
	  }}
	],
	[#Rule 28
		 'declare', 5,
sub
#line 132 "pidl/idl.yp"
{{
	             "TYPE" => "DECLARE", 
                     "PROPERTIES" => $_[2],
		     "NAME" => $_[4],
		     "DATA" => $_[3],
		     "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		     "LINE" => $_[0]->YYData->{LINE},
        }}
	],
	[#Rule 29
		 'decl_type', 1, undef
	],
	[#Rule 30
		 'decl_type', 1, undef
	],
	[#Rule 31
		 'decl_type', 1, undef
	],
	[#Rule 32
		 'decl_enum', 1,
sub
#line 146 "pidl/idl.yp"
{{
                     "TYPE" => "ENUM"
        }}
	],
	[#Rule 33
		 'decl_bitmap', 1,
sub
#line 152 "pidl/idl.yp"
{{
                     "TYPE" => "BITMAP"
        }}
	],
	[#Rule 34
		 'decl_union', 1,
sub
#line 158 "pidl/idl.yp"
{{
                     "TYPE" => "UNION"
        }}
	],
	[#Rule 35
		 'typedef', 6,
sub
#line 164 "pidl/idl.yp"
{{
	             "TYPE" => "TYPEDEF", 
                     "PROPERTIES" => $_[2],
		     "NAME" => $_[4],
		     "DATA" => $_[3],
		     "ARRAY_LEN" => $_[5],
		     "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		     "LINE" => $_[0]->YYData->{LINE},
        }}
	],
	[#Rule 36
		 'typedef', 5,
sub
#line 174 "pidl/idl.yp"
{
		    $_[4]->{TYPE} = "DECORATED";
		    $_[4]->{DATA_TYPE} = $_[3];
		    {
		    "TYPE" => "TYPEDEF",
		    "PROPERTIES" => $_[2],
		    "NAME" => $_[4]->{NAME},
		    "DATA" => $_[4],
		    "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		    "LINE" => $_[0]->YYData->{LINE}
		    }
	}
	],
	[#Rule 37
		 'declarator', 1, undef
	],
	[#Rule 38
		 'declarator', 2,
sub
#line 190 "pidl/idl.yp"
{
		    $_[2]->{LEVELS} = [] unless $_[2]->{LEVELS};
		    push (@{$_[2]->{LEVELS}}, { "TYPE" => "POINTER" });
		    $_[2]->{POINTERS}++;
		    $_[2]
	}
	],
	[#Rule 39
		 'direct_declarator', 1,
sub
#line 199 "pidl/idl.yp"
{{
		    "NAME" => $_[1],
		    "POINTERS" => 0
	}}
	],
	[#Rule 40
		 'direct_declarator', 3, undef
	],
	[#Rule 41
		 'direct_declarator', 4,
sub
#line 205 "pidl/idl.yp"
{
		    $_[1]->{LEVELS} = [] unless $_[1]->{LEVELS};
		    push (@{$_[1]->{LEVELS}}, { 'TYPE' => 'ARRAY', 'SIZE_IS' => $_[3] });
		    $_[1]->{ARRAY_LEN} = [] unless $_[1]->{ARRAY_LEN};
		    push @{$_[1]->{ARRAY_LEN}}, ($_[3] ne '') ? $_[3] : '*';
		    $_[1]
	}
	],
	[#Rule 42
		 'usertype', 1, undef
	],
	[#Rule 43
		 'usertype', 1, undef
	],
	[#Rule 44
		 'usertype', 1, undef
	],
	[#Rule 45
		 'usertype', 1, undef
	],
	[#Rule 46
		 'typedecl', 2,
sub
#line 218 "pidl/idl.yp"
{ $_[1] }
	],
	[#Rule 47
		 'sign', 1, undef
	],
	[#Rule 48
		 'sign', 1, undef
	],
	[#Rule 49
		 'existingtype', 0, undef
	],
	[#Rule 50
		 'existingtype', 2,
sub
#line 223 "pidl/idl.yp"
{ "$_[1] $_[2]" }
	],
	[#Rule 51
		 'existingtype', 1, undef
	],
	[#Rule 52
		 'type', 1, undef
	],
	[#Rule 53
		 'type', 1, undef
	],
	[#Rule 54
		 'type', 1,
sub
#line 227 "pidl/idl.yp"
{ "void" }
	],
	[#Rule 55
		 'enum_body', 3,
sub
#line 229 "pidl/idl.yp"
{ $_[2] }
	],
	[#Rule 56
		 'opt_enum_body', 0, undef
	],
	[#Rule 57
		 'opt_enum_body', 1, undef
	],
	[#Rule 58
		 'enum', 3,
sub
#line 232 "pidl/idl.yp"
{{
             "TYPE" => "ENUM", 
			 "NAME" => $_[2],
		     "ELEMENTS" => $_[3]
        }}
	],
	[#Rule 59
		 'enum_elements', 1,
sub
#line 240 "pidl/idl.yp"
{ [ $_[1] ] }
	],
	[#Rule 60
		 'enum_elements', 3,
sub
#line 241 "pidl/idl.yp"
{ push(@{$_[1]}, $_[3]); $_[1] }
	],
	[#Rule 61
		 'enum_element', 1, undef
	],
	[#Rule 62
		 'enum_element', 3,
sub
#line 245 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 63
		 'bitmap_body', 3,
sub
#line 248 "pidl/idl.yp"
{ $_[2] }
	],
	[#Rule 64
		 'opt_bitmap_body', 0, undef
	],
	[#Rule 65
		 'opt_bitmap_body', 1, undef
	],
	[#Rule 66
		 'bitmap', 3,
sub
#line 251 "pidl/idl.yp"
{{
             "TYPE" => "BITMAP", 
			 "NAME" => $_[2],
		     "ELEMENTS" => $_[3]
        }}
	],
	[#Rule 67
		 'bitmap_elements', 1,
sub
#line 259 "pidl/idl.yp"
{ [ $_[1] ] }
	],
	[#Rule 68
		 'bitmap_elements', 3,
sub
#line 260 "pidl/idl.yp"
{ push(@{$_[1]}, $_[3]); $_[1] }
	],
	[#Rule 69
		 'opt_bitmap_elements', 0, undef
	],
	[#Rule 70
		 'opt_bitmap_elements', 1, undef
	],
	[#Rule 71
		 'bitmap_element', 3,
sub
#line 265 "pidl/idl.yp"
{ "$_[1] ( $_[3] )" }
	],
	[#Rule 72
		 'struct_body', 3,
sub
#line 268 "pidl/idl.yp"
{ $_[2] }
	],
	[#Rule 73
		 'opt_struct_body', 0, undef
	],
	[#Rule 74
		 'opt_struct_body', 1, undef
	],
	[#Rule 75
		 'struct', 3,
sub
#line 272 "pidl/idl.yp"
{{
             "TYPE" => "STRUCT", 
			 "NAME" => $_[2],
		     "ELEMENTS" => $_[3]
        }}
	],
	[#Rule 76
		 'empty_element', 2,
sub
#line 280 "pidl/idl.yp"
{{
		 "NAME" => "",
		 "TYPE" => "EMPTY",
		 "PROPERTIES" => $_[1],
		 "POINTERS" => 0,
		 "ARRAY_LEN" => [],
		 "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		 "LINE" => $_[0]->YYData->{LINE},
	 }}
	],
	[#Rule 77
		 'base_or_empty', 2, undef
	],
	[#Rule 78
		 'base_or_empty', 1, undef
	],
	[#Rule 79
		 'optional_base_element', 2,
sub
#line 294 "pidl/idl.yp"
{ $_[2]->{PROPERTIES} = FlattenHash([$_[1],$_[2]->{PROPERTIES}]); $_[2] }
	],
	[#Rule 80
		 'union_elements', 0, undef
	],
	[#Rule 81
		 'union_elements', 2,
sub
#line 299 "pidl/idl.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 82
		 'union_body', 3,
sub
#line 302 "pidl/idl.yp"
{ $_[2] }
	],
	[#Rule 83
		 'opt_union_body', 0, undef
	],
	[#Rule 84
		 'opt_union_body', 1, undef
	],
	[#Rule 85
		 'union', 3,
sub
#line 306 "pidl/idl.yp"
{{
             "TYPE" => "UNION", 
		     "NAME" => $_[2],
		     "ELEMENTS" => $_[3]
        }}
	],
	[#Rule 86
		 'base_element', 5,
sub
#line 314 "pidl/idl.yp"
{{
			   "NAME" => $_[4],
			   "TYPE" => $_[2],
			   "PROPERTIES" => $_[1],
			   "POINTERS" => $_[3],
			   "ARRAY_LEN" => $_[5],
		       "FILE" => $_[0]->YYData->{INPUT_FILENAME},
		       "LINE" => $_[0]->YYData->{LINE},
              }}
	],
	[#Rule 87
		 'pointers', 0,
sub
#line 328 "pidl/idl.yp"
{ 0 }
	],
	[#Rule 88
		 'pointers', 2,
sub
#line 329 "pidl/idl.yp"
{ $_[1]+1 }
	],
	[#Rule 89
		 'element_list1', 0, undef
	],
	[#Rule 90
		 'element_list1', 3,
sub
#line 334 "pidl/idl.yp"
{ push(@{$_[1]}, $_[2]); $_[1] }
	],
	[#Rule 91
		 'element_list2', 0, undef
	],
	[#Rule 92
		 'element_list2', 1, undef
	],
	[#Rule 93
		 'element_list2', 1,
sub
#line 340 "pidl/idl.yp"
{ [ $_[1] ] }
	],
	[#Rule 94
		 'element_list2', 3,
sub
#line 341 "pidl/idl.yp"
{ push(@{$_[1]}, $_[3]); $_[1] }
	],
	[#Rule 95
		 'array_len', 0, undef
	],
	[#Rule 96
		 'array_len', 3,
sub
#line 346 "pidl/idl.yp"
{ push(@{$_[3]}, "*"); $_[3] }
	],
	[#Rule 97
		 'array_len', 4,
sub
#line 347 "pidl/idl.yp"
{ push(@{$_[4]}, "$_[2]"); $_[4] }
	],
	[#Rule 98
		 'property_list', 0, undef
	],
	[#Rule 99
		 'property_list', 4,
sub
#line 353 "pidl/idl.yp"
{ FlattenHash([$_[1],$_[3]]); }
	],
	[#Rule 100
		 'properties', 1,
sub
#line 356 "pidl/idl.yp"
{ $_[1] }
	],
	[#Rule 101
		 'properties', 3,
sub
#line 357 "pidl/idl.yp"
{ FlattenHash([$_[1], $_[3]]); }
	],
	[#Rule 102
		 'property', 1,
sub
#line 360 "pidl/idl.yp"
{{ "$_[1]" => "1"     }}
	],
	[#Rule 103
		 'property', 4,
sub
#line 361 "pidl/idl.yp"
{{ "$_[1]" => "$_[3]" }}
	],
	[#Rule 104
		 'commalisttext', 1, undef
	],
	[#Rule 105
		 'commalisttext', 3,
sub
#line 371 "pidl/idl.yp"
{ "$_[1],$_[3]" }
	],
	[#Rule 106
		 'anytext', 0,
sub
#line 375 "pidl/idl.yp"
{ "" }
	],
	[#Rule 107
		 'anytext', 1, undef
	],
	[#Rule 108
		 'anytext', 1, undef
	],
	[#Rule 109
		 'anytext', 1, undef
	],
	[#Rule 110
		 'anytext', 3,
sub
#line 377 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 111
		 'anytext', 3,
sub
#line 378 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 112
		 'anytext', 3,
sub
#line 379 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 113
		 'anytext', 3,
sub
#line 380 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 114
		 'anytext', 3,
sub
#line 381 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 115
		 'anytext', 3,
sub
#line 382 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 116
		 'anytext', 3,
sub
#line 383 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 117
		 'anytext', 3,
sub
#line 384 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 118
		 'anytext', 3,
sub
#line 385 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 119
		 'anytext', 3,
sub
#line 386 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 120
		 'anytext', 3,
sub
#line 387 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 121
		 'anytext', 3,
sub
#line 388 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 122
		 'anytext', 3,
sub
#line 389 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]" }
	],
	[#Rule 123
		 'anytext', 5,
sub
#line 390 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]$_[4]$_[5]" }
	],
	[#Rule 124
		 'anytext', 5,
sub
#line 391 "pidl/idl.yp"
{ "$_[1]$_[2]$_[3]$_[4]$_[5]" }
	],
	[#Rule 125
		 'identifier', 1, undef
	],
	[#Rule 126
		 'optional_identifier', 1, undef
	],
	[#Rule 127
		 'optional_identifier', 0, undef
	],
	[#Rule 128
		 'constant', 1, undef
	],
	[#Rule 129
		 'text', 1,
sub
#line 405 "pidl/idl.yp"
{ "\"$_[1]\"" }
	],
	[#Rule 130
		 'optional_semicolon', 0, undef
	],
	[#Rule 131
		 'optional_semicolon', 1, undef
	]
],
                                  @_);
    bless($self,$class);
}

#line 416 "pidl/idl.yp"


#####################################################################
# flatten an array of hashes into a single hash
sub FlattenHash($) 
{ 
    my $a = shift;
    my %b;
    for my $d (@{$a}) {
	for my $k (keys %{$d}) {
	    $b{$k} = $d->{$k};
	}
    }
    return \%b;
}



#####################################################################
# traverse a perl data structure removing any empty arrays or
# hashes and any hash elements that map to undef
sub CleanData($)
{
    sub CleanData($);
    my($v) = shift;
	return undef if (not defined($v));
    if (ref($v) eq "ARRAY") {
	foreach my $i (0 .. $#{$v}) {
	    CleanData($v->[$i]);
	    if (ref($v->[$i]) eq "ARRAY" && $#{$v->[$i]}==-1) { 
		    $v->[$i] = undef; 
		    next; 
	    }
	}
	# this removes any undefined elements from the array
	@{$v} = grep { defined $_ } @{$v};
    } elsif (ref($v) eq "HASH") {
	foreach my $x (keys %{$v}) {
	    CleanData($v->{$x});
	    if (!defined $v->{$x}) { delete($v->{$x}); next; }
	    if (ref($v->{$x}) eq "ARRAY" && $#{$v->{$x}}==-1) { delete($v->{$x}); next; }
	}
    }
	return $v;
}

sub _Error {
    if (exists $_[0]->YYData->{ERRMSG}) {
		print $_[0]->YYData->{ERRMSG};
		delete $_[0]->YYData->{ERRMSG};
		return;
	};
	my $line = $_[0]->YYData->{LINE};
	my $last_token = $_[0]->YYData->{LAST_TOKEN};
	my $file = $_[0]->YYData->{INPUT_FILENAME};
	
	print "$file:$line: Syntax error near '$last_token'\n";
}

sub _Lexer($)
{
	my($parser)=shift;

    $parser->YYData->{INPUT} or return('',undef);

again:
	$parser->YYData->{INPUT} =~ s/^[ \t]*//;

	for ($parser->YYData->{INPUT}) {
		if (/^\#/) {
			if (s/^\# (\d+) \"(.*?)\"(( \d+){1,4}|)//) {
				$parser->YYData->{LINE} = $1-1;
				$parser->YYData->{INPUT_FILENAME} = $2;
				goto again;
			}
			if (s/^\#line (\d+) \"(.*?)\"( \d+|)//) {
				$parser->YYData->{LINE} = $1-1;
				$parser->YYData->{INPUT_FILENAME} = $2;
				goto again;
			}
			if (s/^(\#.*)$//m) {
				goto again;
			}
		}
		if (s/^(\n)//) {
			$parser->YYData->{LINE}++;
			goto again;
		}
		if (s/^\"(.*?)\"//) {
			$parser->YYData->{LAST_TOKEN} = $1;
			return('TEXT',$1); 
		}
		if (s/^(\d+)(\W|$)/$2/) {
			$parser->YYData->{LAST_TOKEN} = $1;
			return('CONSTANT',$1); 
		}
		if (s/^([\w_]+)//) {
			$parser->YYData->{LAST_TOKEN} = $1;
			if ($1 =~ 
			    /^(coclass|interface|const|typedef|declare|union
			      |struct|enum|bitmap|void|unsigned|signed|import|include
				  |importlib)$/x) {
				return $1;
			}
			return('IDENTIFIER',$1);
		}
		if (s/^(.)//s) {
			$parser->YYData->{LAST_TOKEN} = $1;
			return($1,$1);
		}
	}
}

sub parse_string
{
	my ($data,$filename) = @_;

	my $self = new Parse::Pidl::IDL;

    $self->YYData->{INPUT_FILENAME} = $filename;
    $self->YYData->{INPUT} = $data;
    $self->YYData->{LINE} = 0;
    $self->YYData->{LAST_TOKEN} = "NONE";

	my $idl = $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );

	return CleanData($idl);
}

sub parse_file($$)
{
	my ($filename,$incdirs) = @_;

	my $saved_delim = $/;
	undef $/;
	my $cpp = $ENV{CPP};
	if (! defined $cpp) {
		$cpp = "cpp";
	}
	my $includes = join('',map { " -I$_" } @$incdirs);
	my $data = `$cpp -D__PIDL__$includes -xc $filename`;
	$/ = $saved_delim;

	return parse_string($data, $filename);
}

1;
