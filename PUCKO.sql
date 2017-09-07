/*

 ###### Valda entiteter: Agent, Hjälpmedel, Fältagent, Gruppledare, Operation, Incident, Rapport ######

Agent(PKEY [Namn, Nr], Lön, Ursprungligt_namn) 
Agent.Fältagent(Kompetens, Specialite, *Totalt antal operationer, *Antal lyckade operationer)
-> SAMBANDSTABELL FÄLTAGENTER_I_OPERATIONER(PKEY[Agent.Namn, Agent.Nr, Operation.Kodnamntyp, Operation.Startdatum, Incident.Namn, Incident.Nr])

Agent.Gruppledare(*Antal operationer med lyckad utgång, *Antal operationer, *%lyckade operationer) 

Hjälpmedel(PKEY[Namn, Nr], Beskrivning)
-> SAMBANDSTABELL FÄLTAGENTERS_FAVORITHJÄLPMEDEL(Hjälpmedel.Namn, Hjälpmedel.Nr, Fältagent.Namn, Fältagent.Nr)
-> SAMBANDSTABELL HJÄLPMEDEL_I_OPERATIONER(Hjälpmede.Namn, Hjälpmedel.Nr, Operation.Kodnamntyp, Operation.Slutdatum, Incident.Namn, Incident.Nr)

Operation(PKEY[Kodnamntyp, Startdatum, Incident], Slutdatum, Sucessrate) -> FK[Gruppledare]

Incident(PKEY[Namn], PKEY[Nr], Plats, *Medelvärde observationers grad)

Rapport(PKEY[Datm, Titel], *Radantal, *Antal_uppföljningar) FK[Incident + Agent]



*/

drop database a15oloal;
create database a15oloal;
use a15oloal;

# Här väljs incidentnamn som primary key, och nr som möjlig kandidatnyckel.
create table Incident(
    Namn varchar(30),
    Nr int UNIQUE NOT NULL,
    Plats varchar(30) NOT NULL,
    medel_observationer int,
    primary key(Namn)
)engine=innodb;

create table Hjälpmedel(
	Namn char(1),
    Nr smallint,
    Beskrivning varchar(30),
    Typ varchar(15),
    Ordningsnummer smallint,
    primary key(Namn, Nr)
)engine=innodb;

# Extra tabell för att lagra ordningsnummer för olika typer.
create table Hjälpmedelstyper(
    Typ varchar(15),
    Ordningsnummer smallint,
    Hjälpmedelnamn char(1),
    Hjälpmedelnr smallint,
    CHECK(Ordningsnummer >= 1 AND Ordningsnummer <= 15),
    primary key(Typ),
    foreign key(Hjälpmedelnamn, Hjälpmedelnr) references Hjälpmedel(Namn, Nr)
)engine=innodb;

#Using Concrete Table Inheritance martinFowler.com
# https://martinfowler.com/eaaCatalog/concreteTableInheritance.html
#Kan inte hantera partiell nedärvning och kan bli oflexibelt, men ger bäst prestanda när sökningar görs. Förväntning: total nedärvning.
create table Gruppledare(
	Namn char(1),
    Nr smallint,
    Lön int,
    Unamn varchar(25),
    lyckade_operationer int,
    n_operationer int,
    andel_lyckade_op decimal(3, 2),
    CHECK(Lön >= 0),
    CHECK(n_operationer >= 0),
    CHECK(lyckade_operationer >= 0),
    primary key(Namn, Nr)
)engine=innodb;

create table Fältagent(
	Namn char(1),
    Nr smallint,
    Lön int,
    Unamn varchar(25),
    Kompetens varchar(30),
    Specialite varchar(30),
    n_operationer int,
    lyckade_operationer int,
    CHECK(Lön >= 0),
    CHECK(n_operationer >= 0),
    CHECK(lyckade_operationer >= 0),
    primary key(Namn, Nr)
)engine=innodb;

create table Operation(
    Kodnamntyp char(3),
    Startdatum date,
    Incidentnamn varchar(30),
    Slutdatum date,
    Framgång_andel float(3),
    Gruppledarnamn char(1),
    Gruppledarnr smallint,
    CHECK (Kodnamntyp LIKE '[A-Z][0-9][0-9]'),
    primary key(Kodnamntyp, Startdatum, Incidentnamn),
    foreign key(Incidentnamn) references Incident(Namn),
    foreign key (Gruppledarnamn, Gruppledarnr) references Gruppledare(Namn, Nr)
)engine=innodb;

create table Operationstyper(
	Kodnamntyp char(3),
    Operationstyp varchar(40),
    primary key (Kodnamntyp),
    foreign key (Kodnamntyp) references Operation(Kodnamntyp)
)engine=innodb;

create table Operationers_hjälpmedel(
	Hjälpmedelnamn char(1),
    Hjälpmedelnr smallint,
    Kodnamntyp char(1),
    Startdatum date,
    Incidentnamn varchar(30),
    primary key(Hjälpmedelnamn, Hjälpmedelnr, Kodnamntyp, Startdatum, Incidentnamn),
    foreign key(Hjälpmedelnamn, Hjälpmedelnr) references Hjälpmedel(Namn, Nr),
    foreign key(Kodnamntyp, Startdatum, Incidentnamn) references Operation(Kodnamntyp, Startdatum, Incidentnamn)
)engine=innodb;

create table Fältagenters_hjälpmedel(
	Hjälpmedelnamn char(1),
    Hjälpmedelnr smallint,
    Fältagentnamn char(1),
    Fältagentnr smallint,
    primary key(Hjälpmedelnamn, Hjälpmedelnr, Fältagentnamn, Fältagentnr),
    foreign key(Hjälpmedelnamn, Hjälpmedelnr) references Hjälpmedel(Namn, Nr),
    foreign key(Fältagentnamn, Fältagentnr) references Fältagent(Namn, Nr)
)engine=innodb;

create table Fältagenter_operationer(
    Fältagentnamn char(1),
    Fältagentnr smallint,
    Kodnamntyp char(1),
    Startdatum date,
    Incidentnamn varchar(30),
    primary key(Fältagentnamn, Fältagentnr, Kodnamntyp, Startdatum, Incidentnamn),
    foreign key(Fältagentnamn, Fältagentnr) references Fältagent(Namn, Nr), 
    foreign key(Kodnamntyp, Startdatum, Incidentnamn) references Operation(Kodnamntyp, Startdatum, Incidentnamn)
)engine=innodb;

create table Rapport(
    Datum date,
    Titel varchar(30),
    n_uppföljningar int,
    n_rader int,
    Fältagentnamn char(1),
    Fältagentnr smallint,
    Gruppledarnamn char(1),
    Gruppledarnr smallint,
    Incidentnamn varchar(30),
    CHECK(n_uppföljningar >= 0),
    primary key(Datum, Titel),
    foreign key (Fältagentnamn, Fältagentnr) references Fältagent(Namn, Nr),
    foreign key (Gruppledarnamn, Gruppledarnr) references Gruppledare(Namn, Nr),
    foreign key (Incidentnamn) references Incident(Namn)
)engine=innodb;
