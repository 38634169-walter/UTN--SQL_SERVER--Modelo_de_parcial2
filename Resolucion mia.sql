GO 
USE ModeloParcial2

---------------------------------------------------
---------------------TESTING 1---------------------
---------------------------------------------------
SELECT DeclaracionGanancias*3 FROM Personas WHERE DNI =1111

SELECT SUM(Importe) FROM Creditos
WHERE DNI=1111 AND Cancelado <> 0 AND IDBanco=1

--TIENE 250.000

--TRIPLE GANANCIAS 300.000

INSERT INTO Creditos(IDBanco,DNI,Fecha,Plazo,Importe,Cancelado)VALUES
(1,1111,'5-11-2021',12,50001,1)

SELECT * FROM Creditos WHERE DNI = 1111
DELETE FROM Creditos WHERE ID = 26

------------------------------------

--1
ALTER TRIGGER TR_INSERTAR_CREDITO ON Creditos
INSTEAD OF INSERT
AS
BEGIN 
	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @importe MONEY
			DECLARE @dni VARCHAR(10)
			DECLARE @idBanco INT
			SELECT @importe=Importe,@dni=DNI,@idBanco=IDBanco FROM inserted

			DECLARE @importeTotal MONEY

			SELECT @importeTotal=SUM(Importe) FROM Creditos
			WHERE DNI=@dni AND Cancelado <> 0 AND IDBanco=@idBanco

			DECLARE @declaracionGanancias MONEY
			SELECT @declaracionGanancias = DeclaracionGanancias FROM Personas WHERE DNI = @dni

			IF @importeTotal + @importe > @declaracionGanancias *3 BEGIN
				RAISERROR('',16,1)
			END
			ELSE BEGIN
				INSERT INTO Creditos (IDBanco,DNI,Fecha,Importe,Plazo,Cancelado)
				SELECT IDBanco,DNI,Fecha,Importe,Plazo,Cancelado FROM inserted
			END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		RAISERROR('NO SE PUEDE OTORGAR EL CREDITO',16,1)
	END CATCH
END

---------------------------------------------------
---------------------TESTING 2---------------------
---------------------------------------------------
SELECT * FROM Creditos
DELETE FROM Creditos WHERE ID=2
-----------------------------------------------------
--2
CREATE TRIGGER TR_CANCELAR_CREDITO ON Creditos
INSTEAD OF DELETE
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @IDCredito BIGINT
			SELECT @IDCredito=ID FROM deleted

			UPDATE Creditos SET Cancelado=1 WHERE ID=@IDCredito

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		RAISERROR('NO SE PUDO CANCELAR',16,1)
	END CATCH
END


---------------------------------------------------
---------------------TESTING 3---------------------
---------------------------------------------------

SELECT AVG(DeclaracionGanancias) FROM Personas 
--PROMEDIO 80.000
SELECT * FROM Personas
--ganancias  id 2 = 150.000 DNI=2222
--ganancias  id 3 = 50.000 DNI=3333

SELECT * FROM Creditos
INSERT INTO Creditos(IDBanco,DNI,Fecha,Importe,Plazo,Cancelado)VALUES
(1,3333,'05-11-2021',12,20,0)
-----------------------------------------------------

--3
ALTER TRIGGER TR_INSERTAR_CREDITO ON Creditos
INSTEAD OF INSERT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @plazo SMALLINT
			DECLARE @dni VARCHAR(10)
			SELECT @plazo=Plazo, @dni=DNI FROM inserted

			DECLARE @declaracionGanancias MONEY
			SELECT @declaracionGanancias=DeclaracionGanancias FROM Personas WHERE DNI=@dni

			DECLARE @PromedioDeclaracionGanancias MONEY
			SELECT @PromedioDeclaracionGanancias=AVG(DeclaracionGanancias) FROM Personas 

			IF(@declaracionGanancias < @PromedioDeclaracionGanancias) BEGIN
				IF @plazo >= 20 BEGIN
					RAISERROR('',16,1)
				END
			END
			INSERT INTO Creditos (IDBanco,DNI,Fecha,Importe,Plazo,Cancelado)
			SELECT IDBanco,DNI,Fecha,Importe,Plazo,Cancelado FROM inserted

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		RAISERROR('NO SE PUDO INSERTAR',16,1)
	END CATCH
END



---------------------------------------------------
---------------------TESTING 4---------------------
---------------------------------------------------

SELECT p.Nombres,p.Apellidos,b.Nombre,b.Tipo,c.Fecha,c.Importe,c.Fecha,c.ID
FROM Creditos AS c
INNER JOIN Personas AS p ON p.DNI = c.DNI
INNER JOIN Bancos AS b ON b.ID = c.IDBanco
WHERE c.Cancelado=0

SELECT p.Nombres,p.Apellidos,b.Nombre,b.Tipo,c.Fecha,c.Importe,c.Fecha
FROM Creditos AS c
INNER JOIN Personas AS p ON p.DNI = c.DNI
INNER JOIN Bancos AS b ON b.ID = c.IDBanco
WHERE Fecha BETWEEN '05-11-2021' AND '06-12-2021' AND c.Cancelado=0

UPDATE Creditos SET Fecha = '06-12-2021' WHERE ID=20

EXEC SP_LISTAR '06-12-2021','05-11-2021'
---------------------------------------------------------

--4
ALTER PROCEDURE SP_LISTAR(
	@fecha1 DATE,
	@fecha2 DATE
)
AS 
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			
			DECLARE @fechaMayor DATE
			DECLARE @fechaMenor DATE

			IF @fecha1 > @fecha2 BEGIN
				SET @fechaMayor = @fecha1
				SET @fechaMenor = @fecha2
			END
			ELSE BEGIN
				SET @fechaMayor = @fecha2
				SET @fechaMenor = @fecha1
			END 

			SELECT p.Nombres,p.Apellidos,b.Nombre,b.Tipo,c.Fecha,c.Importe
			FROM Creditos AS c
			INNER JOIN Personas AS p ON p.DNI = c.DNI
			INNER JOIN Bancos AS b ON b.ID = c.IDBanco
			WHERE Fecha BETWEEN @fechaMenor AND @fechaMayor AND c.Cancelado=0

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		RAISERROR('NO SE PUDO LISTAR',16,1)
	END CATCH
END