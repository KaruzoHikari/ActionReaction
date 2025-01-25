
# ActionReaction:
# This Perl script allows you to adjust a chemical reaction automatically.
# Developed in 2021 for a university subject (hence why it's in Spanish).


# ===================
#      INICIO
# ===================
use strict vars;
use utf8;
use open 'locale';

print("
  ___       _   _            ______                _   _             
 / _ \\     | | (_)           | ___ \\              | | (_)            
/ /_\\ \\ ___| |_ _  ___  _ __ | |_/ /___  __ _  ___| |_ _  ___  _ __  
|  _  |/ __| __| |/ _ \\| '_ \\|    // _ \\/ _` |/ __| __| |/ _ \\| '_ \\ 
| | | | (__| |_| | (_) | | | | |\\ \\  __/ (_| | (__| |_| | (_) | | | |
\\_| |_/\\___|\\__|_|\\___/|_| |_\\_| \\_\\___|\\__,_|\\___|\\__|_|\\___/|_| |_|
");
print("\n=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\nIntroduce la reacción química.\nEjemplo: BaO2 + HCl => BaCl2 + H2O2\n=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n\n   Reacción:\n   ");
chomp(my $reaction = <STDIN>);
$reaction = trim($reaction);
if($reaction !~ /=>/) {
	die("¡La sintaxis no es correcta!\nDebes separar ambos lados de la reacción con '=>'\n");
}

# Aquí guardamos las moléculas con su notación inicial, para usar la misma notación a la hora de mostrar el resultado
my ($originalReactStr,$originalProductStr) = split(/=>/,$reaction,2);
my @originalReactants = getAllMolecules($originalReactStr);
my @originalProducts = getAllMolecules($originalProductStr);

# Deshacemos los paréntesis de las moléculas
unfoldParentheses();

# Volvemos a guardar las moléculas en nuevos arrays, esta vez con los paréntesis ya deshechos.
my ($reactantsStr,$productsStr) = split(/=>/,$reaction,2);
my @initReactants = getAllMolecules($reactantsStr);
my @initProducts = getAllMolecules($productsStr);

# Creamos los arrays de hashes de los reactivos y productos. Cada uno de estos hashes representa una molécula
# Las llaves del hash serán los átomos de la molecula, y su valor correspondiente será el nº de veces que aparece ese átomo en la molécula. 
my @totalElements = ();
my @reactantsHashes = calculateHashes(@initReactants);
my @productsHashes = calculateHashes(@initProducts);
my $reactionLength = scalar(@reactantsHashes) + scalar(@productsHashes);

# Definimos todas las ecuaciones que se tienen que cumplir para que la reacción esté ajustada
my @equations = ();
foreach my $element (@totalElements) {
	my $first = getElementEquation($element,0,@reactantsHashes);
	my $second = getElementEquation($element,scalar(@reactantsHashes),@productsHashes);
	my $equation = "$first=$second";
	push(@equations,$equation);
}

# Creamos un hash cuyas llaves serán las letras asignadas a cada molécula, y su valor será el valor asignado a esa letra
my %assignedValues = ();
for(my $i = 0; $i < $reactionLength; $i++) {
	my $letter = getLetter($i);
	$assignedValues{$letter} = 1;
}

# Empezamos el ciclo para asignar valores a las letras. En este caso, 0 representa la primera letra.
assignNumberToLetter(0);

# Si ha llegado hasta aquí y no ha salido del programa, es que no ha encontrado una solución válida para la ecuación.
print("\nNo se ha encontrado ninguna solución válida para esta reacción.\n");



# ===================
#      FUNCIONES
# ===================
sub assignNumberToLetter {
	my ($index) = @_;
	for(my $i = 1; $i <= 16; $i++) {
		checkEquations();
		$assignedValues{getLetter($index)} = $i;
		if($index < $reactionLength - 1) {
			assignNumberToLetter($index + 1);
		}
	}
}

sub checkEquations {
	my $isValid = 1;
	foreach my $equation (@equations) {
		if($isValid == 1) {
			# Primero se sustituyen las variables en la ecuación por el valor asignado actualmente.
			my $finalEq = $equation;
			for(my $i = 0; $i < $reactionLength; $i++) {
				my $letter = getLetter($i);
				my $value = $assignedValues{$letter};
				$finalEq = $finalEq =~ s/$letter/$value/r;
			}
		
			# Después se comprueba si la ecuación es correcta.
			my ($firstPart,$secondPart) = split(/=/,$finalEq,2);
			my $firstResult = eval("$firstPart");
			my $secondResult = eval("$secondPart");
			if($firstResult != $secondResult) {
				$isValid = 0;
			}
		}
	}
	
	if($isValid == 1) {
		my $finalMessage = "\n\n=-=-=-=-=-=-= REACCIÓN AJUSTADA =-=-=-=-=-=-=\n";
		
		my $finalReaction = "";
		my $key = "a";
		for(my $i = 0; $i < scalar(%assignedValues); $i++) { 
			my $number = $assignedValues{$key};
			my $molecule = getOriginalMolecule($key);
			
			my $newReactionPart = "";
			if($number > 1) {
				$newReactionPart = "$number*$molecule";
			} else {
				$newReactionPart = "$molecule";
			}
			
			my $concatenationSymbol = "";
			if($i > 0) {
				$concatenationSymbol = " + ";
			}
			if($i == scalar(@originalReactants)) {
				$concatenationSymbol = " => ";
			}
			
			$finalMessage = join($concatenationSymbol,$finalMessage,$newReactionPart);
			$key++;
		}
		
		print("$finalMessage\n");
		print("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n\n");
		exit();
	}
}

sub getOriginalMolecule {
	my ($letter) = @_;
	my $number = getNumber($letter);
	my $originalReactantsLength = scalar(@originalReactants);
	if($number < $originalReactantsLength) {
		return $originalReactants[$number];
	} else {
		return $originalProducts[$number-$originalReactantsLength];
	}
}

sub getLetter {
	my ($index) = @_;
	
	my $letter = "a";
	for(my $i = 0; $i < $index; $i++) {
		$letter++;
	}
	
	return $letter;
}

sub getNumber {
	my ($letterToFind) = @_;
	
	my $letter = "a";
	for(my $i = 0; $i < 100; $i++) {
		if($letter eq $letterToFind) {
			return $i;
		}
		$letter++;
	}
	
	return 0;
}

sub getAllMolecules {
	my ($reactionPart) = @_;
	my @allMolecules = split(/\+/,$reactionPart);
	for(my $i = 0; $i < scalar(@allMolecules); $i++) {
		my $molecule = $allMolecules[$i];
		if(substr($molecule,0,1) =~ /[0-9]/) {
			$allMolecules[$i] = substr($molecule,1,length($molecule)-1);
		}
	}
	return @allMolecules;
}

sub getElementEquation {
	my ($atom,$letterOffset,@hashes) = @_;
	
	my $letter = getLetter($letterOffset);
	
	my @parts = ();
	for(my $i = 0; $i < scalar(@hashes); $i++) {
		# Obtenemos el hash que representa 1 molécula
		my %hashReact = %{$hashes[$i]};
		
		# Iteramos el hash, cuyas llaves son los átomos de la molécula, y el valor el nº de veces que aparece
		if(exists $hashReact{$atom}) {
			my $number = $hashReact{$atom};
			push(@parts,"$number*$letter");
		}
		
		# Incrementamos la letra ya que pasamos a la siguiente molécula de la reacción
		$letter++;
	}
	
	return join("+",@parts);
}

sub unfoldParentheses {
	
	my @characters = split(//, $reaction);
	my $length = scalar(@characters);
	my %replaceCases = ();
	
	for(my $i = 0; $i < $length; $i++) {
		# Buscamos el paréntesis de una molécula
		if($characters[$i] =~ /\(/) {
			my %hashReact = ();
			my $parenthesis = findClosingParenthesis($i);
			my $parenthesisNumber = int(substr($parenthesis,length($parenthesis)-1,1));
			
			# Iteramos la molécula con parentésis buscando del número de cada átomo, y multiplicando por el valor del paréntesis
			my %hashReact = getAtomHash(substr($parenthesis,1,length($parenthesis)-2));
			my $finalString = "";
			foreach my $atom (keys %hashReact) {
				my $number = $hashReact{$atom};
				$number *= $parenthesisNumber;
				$finalString = join("",($finalString,"$atom$number"));
			}
			
			$replaceCases{$parenthesis} = $finalString;
		}
	}
	
	foreach my $key (keys %replaceCases) {
		my $replacement = $replaceCases{$key};
		$reaction =~ s/\Q$key/\Q$replacement/g;
	}
}

sub findClosingParenthesis {
	my ($index) = @_;
	
	my @characters = split(//, $reaction);
	my $length = scalar(@characters);
	for(my $i = $index; $i < $length; $i++) {
		if($characters[$i] =~ /\)/) {
			return substr($reaction,$index,$i+2-$index);
		}
	}
	
	die("¡Hay un reactivo/producto con paréntesis sin cerrar!\nSaliendo del programa...");
}

sub getAtomHash {
	
	my ($molecule) = @_;
	
	my %hashReact = ();
	my @characters = split(//, $molecule);
	my $length = scalar(@characters);

	for(my $i = 0; $i < $length; $i++) {
		if($characters[$i] =~ /[A-Z]/) {
			my $atom = $characters[$i];
			my $numPointer = $i+1;
			if($i != $length-1 and $characters[$i+1] =~ /[a-z]/) {
				$atom = join("",($characters[$i],$characters[$i+1]));
				$numPointer++;
			}
			if(isAtom($atom) == 0) {
				die("\n¡$atom no es un elemento químico válido!\n");
			}
		
			my $number = 1;
			if($length > $numPointer and $characters[$numPointer] =~ /[0-9]/) {
				$number = int($characters[$numPointer]);
			}
		
			$hashReact{$atom} = $number;
			
			# Si el elemento no ha sido añadido antes a la lista de elementos de la reacción, lo añadimos
			if(hasAtomBeenAdded($atom) == 0) {
				push(@totalElements,$atom);
			}
		}
	}
	
	return %hashReact;
	
}

sub calculateHashes {
	my (@initAtoms) = @_;
	my @hashes = ();
	foreach my $react (@initAtoms) {
		my %hashReact = getAtomHash($react);
		my $hashRef = \%hashReact;
		push(@hashes,$hashRef);
	}
	
	return @hashes;
}

sub hasAtomBeenAdded {
	my ($atom) = @_;
	foreach my $checkAtom (@totalElements) {
		if($atom eq $checkAtom) {
			return 1;
		}
	}
	return 0;
}

sub isAtom {
	my ($atom) = @_;
	my @validAtoms = ("H","Li","Na","K","Rb","Cs","Fr","Be","Mg","Ca","Sr","Ba","Ra","Sc","Y","La","Ce","Pr","Nd","Pm","Sm","Eu","Gd","Tb","Dy","Ho","Er","Tm","Yb","Lu",
	"Ac","Th","Pa","U","Np","Pu","Am","Cm","Bk","Cf","Es","Fm","Md","No","Lr","Ti","Zr","Hf","Rf","V","Nb","Ta","Db","Cr","Mo","W","Sg","Mn","Tc","Re","Bh","Fe","Co","Ni",
	"Ru","Rh","Pd","Os","Ir","Pt","Hs","Mt","Ds","Cu","Ag","Au","Rg","Zn","Cd","Hg","Cn","B","Al","Ga","In","Tl","Nh","C","Si","Ge","Sn","Pb","Fl","N","P","As","Sb","Bi",
	"Mc","O","S","Se","Te","Po","Lv","F","Cl","Br","I","At","Ts","He","Ne","Ar","Kr","Xe","Rn","Og");
	foreach my $checkAtom (@validAtoms) {
		if($atom eq $checkAtom) {
			return 1;
		}
	}
	return 0;
}

sub trim {
	my ($line) = @_;
	chomp($line);
	return $line =~ s/ //gr;
}