drop database bus;
create database bus;
use bus;
#plan to use mysql password encryption. It will go for a length around 250
create table BusOwner(
	ID varchar(5),
	Name varchar(100) not null,
	UserName varchar(100) unique not null,
	Password varchar(300) not null,
	Nic varchar(10) unique not null,
	Email varchar(100),
	PRIMARY KEY(ID)
);
#Bus owner ID is produced by the application. It won't change. The row can be only deleted. Thus only 'on delete cascade'
create table Bus(
	RegNumber varchar(10),
	BusOwnerID varchar(5),
	phoneNumber int(10),
	NoSeat int(3),
	Type varchar(15),
	wifi bit not null default 0,
	haveCurtains bit default 0,
	password varchar(300) not null,
	PRIMARY KEY(RegNumber),
	FOREIGN KEY(BusOwnerID) REFERENCES BusOwner(ID)
	on delete cascade
);
#RegNumber of the bus is a user insertion field. user can enter it wrongly. Thus he may need to change it later. Hence require both on update/delete cascade
#number is to have a order of photoes for a bus. A single bus may have none or more photoes.
create table Image(
	RegNumber varchar(10),
	ImagePath varchar(10) not null,
	PRIMARY KEY(RegNumber,ImagePath),
	FOREIGN KEY(RegNumber) REFERENCES Bus(RegNumber)
	on delete cascade
	on update cascade
);
create table Route(
	RouteID int(4),
	PRIMARY KEY(RouteID)
);
#Town name is the name we get from google.
create  table Location(
	TownID varchar(5),
	TownName varchar(200) not null,
	GMAPLink varchar(200),
	PRIMARY KEY(TownID)
);
# Distance is the distance to the town from the start of the route
#Town may get deleted. (Express halt change)
create table RouteDestination(
	RouteID int(5),
	TownID varchar(5),
	Distance int(3) not null,
	PRIMARY KEY(RouteID,TownID),
	FOREIGN KEY(RouteID) REFERENCES Route(RouteID)
	on delete cascade
	on update cascade,
	FOREIGN KEY(TownID) REFERENCES Location(TownID)
	on delete cascade
	on update cascade
);
#Duration is the total time taken for the journey
create table BusJourney(
	BusJourneyID varchar(10),
	RegNumber varchar(10) unique,
	RouteID int(5),
	FromTown varchar(5),
	ToTown varchar(5),
	Duration bigint not null,
	PRIMARY KEY(BusJourneyID),
	FOREIGN KEY(RegNumber) REFERENCES Bus(RegNumber)
	on delete cascade
	on update cascade,
	FOREIGN KEY(RouteID) REFERENCES Route(RouteID),
	FOREIGN KEY(FromTown) REFERENCES Location(TownID),
	FOREIGN KEY(ToTown) REFERENCES Location(TownID)
);

create table Schedule(
	ScheduleID varchar(8),
	BusJourneyID varchar(6),
	FromTown varchar(5) not null,
	FromTime bigint not null,
	ToTime bigint,
	Valid bit default 1,
	PRIMARY KEY(ScheduleID),
	FOREIGN KEY(BusJourneyID) REFERENCES BusJourney(BusJourneyID),
	FOREIGN KEY(FromTown) REFERENCES Location(TownID)
);
create table Booking(
	TicketNo varchar(10),
	ScheduleID varchar(8),
	CustomerName varchar(150) not null,
	State varchar(10) not null,
	Nic varchar(10) not null,
	Email varchar(150) not null,
	Payment Numeric(4,2), 
	PaypalPayment varchar(200),
	FromTown varchar(5),
	ToTown varchar(5),
	PRIMARY KEY(TicketNo),
	FOREIGN KEY(ScheduleID) REFERENCES Schedule(ScheduleID),
	FOREIGN KEY(FromTown) REFERENCES Location(TownID),
	FOREIGN KEY(ToTown) REFERENCES Location(TownID)
);
create table Admin (
	AdminID varchar(4),
	Name varchar(100) unique,
	Password varchar(300) not null,
	CostPerKm Numeric(4,2) not null,
	Primary Key(AdminID)
);

delimiter //
drop trigger if exists BusJourney_check1 //
create trigger BusJourney_check1 before insert on BusJourney 

	for each row
	begin
		if not (exists (select * from RouteDestination where RouteDestination.RouteID = new.RouteID and new.FromTown = RouteDestination.TownID) and 
			exists (select * from RouteDestination where RouteDestination.RouteID = new.RouteID and new.ToTown = RouteDestination.TownID)) then
			signal sqlstate '45001' set message_text = 'RouteID mismatch';
		end if;
	end //

delimiter ;

delimiter //
drop trigger if exists BusJourney_check2 //
create trigger BusJourney_check2 before update on BusJourney 

	for each row
	begin
		if not (exists (select * from RouteDestination where RouteDestination.RouteID = new.RouteID and new.FromTown = RouteDestination.TownID) and 
			exists (select * from RouteDestination where RouteDestination.RouteID = new.RouteID and new.ToTown = RouteDestination.TownID)) then
			signal sqlstate '45001' set message_text = 'RouteID mismatch';
		end if;
	end //

delimiter ;

delimiter //
drop trigger if exists BusOwner_check1 //
create trigger BusOwner_check1 before insert on BusOwner 

	for each row
	begin
		if ( 
			exists (select * from Admin where Admin.Name = new.UserName) or
			exists (select * from Bus where Bus.RegNumber = new.UserName)
			) then
		signal sqlstate '45000' set message_text = 'BusOwner: UserName not unique';
		end if;
	end //

delimiter ;

delimiter //
drop trigger if exists BusOwner_check2 //
create trigger BusOwner_check2 before update on BusOwner 

	for each row
	begin
		if ( 
			exists (select * from Admin where Admin.Name = new.UserName) or
			exists (select * from Bus where Bus.RegNumber = new.UserName)
			) then
		signal sqlstate '45000' set message_text = 'BusOwner: UserName not unique';
		end if;
	end //

delimiter ;

delimiter //
drop trigger if exists Admin_check1 //
create trigger Admin_check1 before insert on Admin 

	for each row
	begin
		if ( 
			exists (select * from BusOwner where BusOwner.UserName = new.Name) or
			exists (select * from Bus where Bus.RegNumber = new.Name)
			) then
		signal sqlstate '45000' set message_text = 'Admin: UserName not unique';
		end if;
	end //

delimiter ;

delimiter //
drop trigger if exists Admin_check2 //
create trigger Admin_check2 before update on Admin 

	for each row
	begin
		if ( 
			exists (select * from BusOwner where BusOwner.UserName = new.Name) or
			exists (select * from Bus where Bus.RegNumber = new.Name)
			) then
		signal sqlstate '45000' set message_text = 'Admin: UserName not unique';
		end if;
	end //

delimiter ;

delimiter //
drop trigger if exists Bus_check1 //
create trigger Bus_check1 before insert on Bus 

	for each row
	begin
		if ( 
			exists (select * from BusOwner where BusOwner.UserName = new.RegNumber) or
			exists (select * from Admin where Admin.Name = new.RegNumber)
			) then
		signal sqlstate '45000' set message_text = 'Bus: UserName not unique';
		end if;

		if (new.NoSeat != 53 and new.NoSeat != 48 and new.NoSeat != 26) then
			signal sqlstate '45003' set message_text = 'Bus: NoSeat not valid';
		end if;

		if (new.Type != 'Super-Luxury' and new.Type != 'Luxury' and new.Type != 'Semi-Luxury' and new.Type != 'Normal') then
			signal sqlstate '45004' set message_text = 'Bus: Type not valid';
		end if;

	end //

delimiter ;

delimiter //
drop trigger if exists Bus_check2 //
create trigger Bus_check2 before update on Bus 

	for each row
	begin
		if ( 
			exists (select * from BusOwner where BusOwner.UserName = new.RegNumber) or
			exists (select * from Admin where Admin.Name = new.RegNumber)
			) then
		signal sqlstate '45000' set message_text = 'Bus: UserName not unique';
		end if;

		if (new.NoSeat != 53 and new.NoSeat != 48 and new.NoSeat != 26) then
			signal sqlstate '45003' set message_text = 'Bus: NoSeat not valid';
		end if;

		if (new.Type != 'Super-Luxury' and new.Type != 'Luxury' and new.Type != 'Semi-Luxury' and new.Type != 'Normal') then
			signal sqlstate '45004' set message_text = 'Bus: Type not valid';
		end if;
		
	end //

delimiter ;



delimiter //
drop trigger if exists Schedule_check1 //
create trigger Schedule_check1 before insert on Schedule
 	for each row
 	begin
     	set new.ToTime = new.FromTime + (select Duration from BusJourney where BusJourney.BusJourneyID = new.BusJourneyID limit 1);
		if (exists
				(select * from Schedule where 
					((new.FromTime between Schedule.FromTime and Schedule.ToTime) or 
					(new.ToTime between Schedule.FromTime and Schedule.ToTime)) and 
					new.BusJourneyID = Schedule.BusJourneyID
				)
			) then
			signal sqlstate '45002' set message_text = 'Schedule: Overlapping schedules';
		end if;
  	end //
delimiter ;



delimiter //
drop trigger if exists Schedule_check2 //
create trigger Schedule_check2 before update on Schedule
 	for each row
 	begin
     	set new.ToTime = new.FromTime + (select Duration from BusJourney where BusJourney.BusJourneyID = new.BusJourneyID limit 1);
		if (exists
				(select * from Schedule where 
					((new.FromTime between Schedule.FromTime and Schedule.ToTime) or 
					(new.ToTime between Schedule.FromTime and Schedule.ToTime)) and 
					new.BusJourneyID = Schedule.BusJourneyID
				)
			) then
			signal sqlstate '45002' set message_text = 'Schedule: Overlapping schedules';
		end if;
  	end //
delimiter ;



INSERT INTO `busowner` (`ID`, `Name`, `UserName`, `Password`, `Nic`, `Email`) VALUES
('1001', 'BusOwner1', 'BO1', '123', '1231231231', NULL),
('1002', 'BusOwner2', 'BO2', '123', '1231231232', NULL),
('1003', 'BusOwner3', 'BO3', '123', '1231231233', NULL),
('1004', 'BusOwner4', 'BO4', '123', '1231231234', NULL),
('1005', 'BusOwner5', 'BO5', '123', '1231231235', NULL),
('1006', 'BusOwner6', 'BO6', '123', '1231231236', NULL);

INSERT INTO `bus` (`RegNumber`, `BusOwnerID`, `phoneNumber`, `NoSeat`, `Type`, `wifi`, `haveCurtains`, `password`) VALUES
('NA-0001', '1001', 77123123, 53, 'Semi-Luxury', b'0', b'0', '123'),
('NA-0002', '1001', 77123123, 53, 'Semi-Luxury', b'1', b'0', '123'),
('NA-0003', '1002', 77123124, 26, 'Normal', b'0', b'0', '123'),
('NA-0004', '1005', 77123122, 53, 'Normal', b'0', b'0', '123'),
('NA-0005', '1001', 77123111, 53, 'Normal', b'0', b'0', '123'),
('NA-0006', '1001', 77123423, 48, 'Semi-Luxury', b'0', b'1', '123'),
('NA-0007', '1003', 77123113, 53, 'Luxury', b'1', b'1', '123'),
('NA-0008', '1003', 77123103, 53, 'Semi-Luxury', b'1', b'1', '123'),
('NA-0009', '1004', 77133123, 48, 'Super-Luxury', b'1', b'1', '123'),
('NA-0010', '1002', 77121123, 53, 'Luxury', b'0', b'0', '123');

INSERT INTO `location` (`TownID`, `TownName`, `GMAPLink`) VALUES
('2001', 'Pettah', 'Pettah+Bus+Stop'),
('2002', 'Kiribathgoda', 'Kiribathgoda Junction Bus Stop, Colombo-Kandy Hwy, Kiribathgoda'),
('2003', 'Nittabuwa', 'Nittabuwa Junction, A1, Nittabuwa'),
('2004', 'Warakapola', 'Warakapola, A1, Ambepussa'),
('2005', 'Polgahawela', 'Polgahawela Bus Station, 06 Kurunegala Road, Polgahawela 037'),
('2006', 'Kurunegala', 'Kurunegala'),
('2007', 'Bambalapitiya', 'Unity Plaza Bus Stop, Galle Rd, Colombo'),
('2008', 'Wellawate', 'Wellawate Mosque Bus Stop, Galle Rd, Colombo'),
('2009', 'Mt. Lavinia', 'Mt. Lavinia Bus Stand, A2, Dehiwala-Mount Lavinia'),
('2010', 'Moratuwa', 'Katubadda, Bandaranayake Mawatha, Moratuwa'),
('2011', 'Panadura', 'SLTB Bus Station, Panadura'),
('2012', 'Piliyandala', 'Piliyandala Bus Stand, Piliyandala'),
('2013', 'Kottawa', 'Kottawa Bus Station, Pannipitiya');

INSERT INTO `route` (`RouteID`) VALUES
(6),
(100),
(255);

INSERT INTO `routedestination` (`RouteID`, `TownID`, `Distance`) VALUES
(6, '2001', 0),
(6, '2002', 10),
(6, '2003', 20),
(6, '2004', 30),
(6, '2005', 40),
(6, '2006', 50),
(100, '2001', 0),
(100, '2007', 15),
(100, '2008', 30),
(100, '2010', 45),
(100, '2011', 60),
(255, '2009', 0),
(255, '2010', 20),
(255, '2012', 40),
(255, '2013', 60);

INSERT INTO `busjourney` (`BusJourneyID`, `RegNumber`, `RouteID`, `FromTown`, `ToTown`, `Duration`) VALUES
('4001', 'NA-0001', 6, '2001', '2006', '10800'),
('4003', 'NA-0002', 6, '2005', '2006', '3600'),
('4005', 'NA-0004', 100, '2001', '2011', '5400'),
('4007', 'NA-0006', 100, '2001', '2010', '3600'),
('4008', 'NA-0007', 100, '2001', '2008', '2400'),
('4010', 'NA-0009', 255, '2009', '2013', '5400');

INSERT INTO `schedule` (`ScheduleID`, `BusJourneyID`, `FromTown`, `FromTime`, `ToTime`, `Valid`) VALUES
('6001', '4001', '2001', 16200, 27000, b'1'),
('6002', '4001', '2006', 30600, 41400, b'1'),
('6003', '4001', '2001', 45000, 55800, b'1'),
('6004', '4001', '2006', 59400, 70200, b'1'),
('6005', '4003', '2001', 30600, 34200, b'1'),
('6006', '4003', '2005', 37800, 41400, b'1'),
('6007', '4003', '2001', 45000, 48600, b'1'),
('6008', '4003', '2005', 52200, 55800, b'1'),
('6009', '4005', '2001', 30600, 36000, b'1'),
('6010', '4005', '2011', 39600, 45000, b'1'),
('6011', '4005', '2001', 55800, 61200, b'1'),
('6012', '4005', '2011', 66600, 72000, b'1'),
('6013', '4007', '2001', 14400, 18000, b'1'),
('6015', '4007', '2001', 21600, 25200, b'1'),
('6017', '4007', '2001', 32400, 36000, b'1'),
('6018', '4007', '2010', 39600, 43200, b'1'),
('6019', '4007', '2001', 46800, 50400, b'1'),
('6020', '4007', '2010', 54000, 57600, b'1'),
('6021', '4007', '2001', 61200, 64800, b'1'),
('6022', '4007', '2010', 68400, 72000, b'1'),
('6023', '4007', '2001', 75600, 79200, b'1'),
('6024', '4007', '2010', 82800, 86400, b'1'),
('6025', '4008', '2001', 25200, 27600, b'1'),
('6026', '4008', '2008', 32400, 34800, b'1'),
('6027', '4008', '2001', 39600, 42000, b'1'),
('6028', '4008', '2008', 46800, 49200, b'1'),
('6029', '4008', '2001', 54000, 56400, b'1'),
('6030', '4008', '2008', 61200, 63600, b'1'),
('6031', '4008', '2001', 68400, 70800, b'1'),
('6032', '4008', '2008', 75600, 78000, b'1'),
('6033', '4010', '2009', 28800, 34200, b'1'),
('6034', '4010', '2013', 36000, 41400, b'1'),
('6035', '4010', '2009', 43200, 48600, b'1'),
('6036', '4010', '2013', 50400, 55800, b'1'),
('6037', '4010', '2009', 57600, 63000, b'1'),
('6038', '4010', '2013', 64800, 70200, b'1'),
('6039', '4010', '2009', 72000, 77400, b'1'),
('6040', '4010', '2013', 79200, 84600, b'1');