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
    primary key(Namn)
)engine=innodb;

# Extra tabell för att lagra ordningsnummer och typ av redskap för olika typer. Typkod är kod för objektet.
create table Hjälpmedelstyper(
	Typkod smallint,
    Ordningsnummer tinyint(2),
    Typ varchar(20),
    CHECK(Ordningsnummer >= 1 AND Ordningsnummer <= 15),
    primary key(Typkod, Ordningsnummer)
)engine=innodb;

create table Hjälpmedel(
	Namn varchar(20),
    Nr smallint,
    Beskrivning varchar(30),
    Typ_n smallint,
    Ordningsnummer tinyint(2),
    primary key(Namn, Nr),
    foreign key(Typ_n, Ordningsnummer) references Hjälpmedelstyper(Typkod, Ordningsnummer)
)engine=innodb;


#Using Concrete Table Inheritance martinFowler.com
# https://martinfowler.com/eaaCatalog/concreteTableInheritance.html
#Kan inte hantera partiell nedärvning och kan bli oflexibelt, men ger bäst prestanda när sökningar görs. Förväntning: total nedärvning.
create table Gruppledare(
	Namn char(1),
    Nr tinyint(2),
    Lön int,
    Förnamn varchar(25),
    Efternamn varchar(25),
    lyckade_operationer int,
    n_operationer int,
    andel_lyckade_op decimal(3, 2),
    CHECK(NOT (Förnamn = 'Leif Loket' AND Efternamn = 'Olsson') OR NOT (Förnamn = 'Greger' AND Efternamn = 'Puckowitz') OR NOT (Förnamn = 'Greve' AND Efternamn = 'Dracula')),
    CHECK(Lön >= 12000 AND Lön <= 35000),
    CHECK(Nr >= 0 AND Nr != 13 AND Nr <= 99),
    CHECK(lyckade_operationer >= 0),
    primary key(Namn, Nr)
)engine=innodb;

/* Trigger to set Lön to 13k if no value is inserted on Gruppledare. */
DELIMITER //
 
CREATE TRIGGER LÖNECHECK_Gruppledare BEFORE INSERT ON Gruppledare
FOR EACH ROW BEGIN
 
  IF(NEW.Lön IS NULL) THEN
    SET NEW.Lön=13000;
  END IF;
 
END;
 
//
DELIMITER ;


create table Fältagent(
	Namn char(1),
    Nr tinyint(2),
    Lön int,
    Förnamn varchar(25),
    Efternamn varchar(25),
    Kompetens varchar(30) NOT NULL,
    Specialite varchar(30) NOT NULL,
    n_operationer int,
    lyckade_operationer int,
    CHECK(Lön >= 12000 AND Lön <= 25000),
    CHECK(NOT(Förnamn = 'Leif Loket' AND Efternamn = 'Olsson') OR NOT (Förnamn = 'Greger' AND Efternamn = 'Puckowitz') OR NOT (Förnamn = 'Greve' AND Efternamn = 'Dracula')),
    CHECK(Nr > 0 AND Nr != 13 AND Nr <= 99),
    CHECK(lyckade_operationer >= 0),
    primary key(Namn, Nr)
)engine=innodb;

/* Trigger to set Lön to 13k if no value is inserted on Fältagent. */
DELIMITER //
 
CREATE TRIGGER LÖNECHECK_Fältagent BEFORE INSERT ON Fältagent
FOR EACH ROW BEGIN
 
  IF(NEW.Lön IS NULL) THEN
    SET NEW.Lön=13000;
  END IF;
 
END;
 
//
DELIMITER ;

create table Operation(
    Kodnamn char(3),
    Operationstyp varchar(40),
    Startdatum date,
    Incidentnamn varchar(30),
    Slutdatum date,
    Sucess_Rate tinyint(1),
    Gruppledarnamn char(1),
    Gruppledarnr tinyint(2),
    CHECK (Kodnamntyp LIKE '[A-Z][0-9][0-9]'),
    CHECK ((DAY(Slutdatum) > DAY(Startdatum) AND (YEAR(Slutdatum) = YEAR(Startdatum))) OR (YEAR(Slutdatum) > YEAR(Startdatum))),
    primary key(Kodnamn, Operationstyp, Startdatum, Incidentnamn),
    foreign key(Incidentnamn) references Incident(Namn),
    foreign key (Gruppledarnamn, Gruppledarnr) references Gruppledare(Namn, Nr)
)engine=innodb;

/*
# Brytit upp Operationer till Operationstyper för att minska redundans
create table Operationstyper(
	Kodnamntyp char(3),
    Operationstyp varchar(40) NOT NULL,
    primary key (Kodnamntyp),
    foreign key (Kodnamntyp) references Operation(Kodnamntyp)
)engine=innodb;
*/

create table Operationers_hjälpmedel(
	Hjälpmedelnamn varchar(20),
    Hjälpmedelnr smallint,
    Kodnamn char(3),
    Operationstyp varchar(40),
    Startdatum date,
    Incidentnamn varchar(30),
    primary key(Hjälpmedelnamn, Hjälpmedelnr, Kodnamn, Operationstyp, Startdatum, Incidentnamn),
    foreign key(Hjälpmedelnamn, Hjälpmedelnr) references Hjälpmedel(Namn, Nr),
    foreign key(Kodnamn, Operationstyp, Startdatum, Incidentnamn) references Operation(Kodnamn, Operationstyp, Startdatum, Incidentnamn)
)engine=innodb;



/* Trigger för att hantera om start- och slutdatum är mindre än 5 veckor mellan varandra */
DELIMITER //
 
CREATE TRIGGER DATUMCHECK_Operation BEFORE INSERT ON Operation
FOR EACH ROW BEGIN
 
  IF((WEEK(NEW.Slutdatum) - WEEK(NEW.Startdatum)) > 5 ) THEN
    SET NEW.Slutdatum = (DATE_ADD(NEW.Startdatum, INTERVAL 5 WEEK));
  END IF;
 
END;
 
//
DELIMITER ;

create table Fältagenters_hjälpmedel(
	Hjälpmedelnamn varchar(20),
    Hjälpmedelnr smallint,
    Fältagentnamn char(1),
    Fältagentnr tinyint(2),
    primary key(Hjälpmedelnamn, Hjälpmedelnr, Fältagentnamn, Fältagentnr),
    foreign key(Hjälpmedelnamn, Hjälpmedelnr) references Hjälpmedel(Namn, Nr),
    foreign key(Fältagentnamn, Fältagentnr) references Fältagent(Namn, Nr)
)engine=innodb;

create table Fältagenter_operationer(
    Fältagentnamn char(1),
    Fältagentnr tinyint(2),
    Kodnamn char(3),
    Operationstyp varchar(40),
    Startdatum date,
    Incidentnamn varchar(30),
    primary key(Fältagentnamn, Fältagentnr, Kodnamn, Operationstyp, Startdatum, Incidentnamn),
    foreign key(Fältagentnamn, Fältagentnr) references Fältagent(Namn, Nr), 
    foreign key(Kodnamn, Operationstyp, Startdatum, Incidentnamn) references Operation(Kodnamn, Operationstyp, Startdatum, Incidentnamn)
)engine=innodb;

create table Slutrapport(
    Datum date,
    Titel varchar(30),
    n_uppföljningar int,
    n_rader int,
    Kommentar varchar(25),
    Typ varchar(16),
    Fältagentnamn char(1),
    Fältagentnr tinyint(2),
    Gruppledarnamn char(1),
    Gruppledarnr tinyint(2),
    Incidentnamn varchar(30),
    CHECK(n_uppföljningar >= 0),
    CHECK((Typ = 'Ledningsrapport') OR (Typ = 'Fältrapport')),
    primary key(Datum, Titel),
    foreign key (Fältagentnamn, Fältagentnr) references Fältagent(Namn, Nr),
    foreign key (Gruppledarnamn, Gruppledarnr) references Gruppledare(Namn, Nr),
    foreign key (Incidentnamn) references Incident(Namn)
)engine=innodb;

insert into Incident (Namn, Nr, Plats) values ('Ulvahändelsen', 5, 'Töreboda');
insert into Operation (Startdatum, Slutdatum, Incidentnamn) values ('2017-01-01', '2017-05-05', 'Ulvahändelsen');
select * from Operation

