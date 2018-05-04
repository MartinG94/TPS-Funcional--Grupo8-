{-# LANGUAGE NoMonomorphismRestriction #-}
import Text.Show.Functions
import Data.List
import Data.Maybe
import Test.Hspec

-- 1ra Parte

type Billetera = Float
type Evento = Billetera -> Billetera

depósito :: Billetera -> Evento
depósito = (+)

extracción :: Billetera -> Evento
extracción dineroARetirar = max 0 . depósito ( -dineroARetirar)

upgrade :: Evento
upgrade billeteraUsuario = (depósito billeteraUsuario . min 10 . (*0.2)) billeteraUsuario

cierreDeCuenta :: Evento
cierreDeCuenta _ = 0

quedaIgual :: Evento
quedaIgual = id

pruebasConEventos = hspec $ do
  describe "Pruebas de los eventos con una billetera de saldo 10" $ do
    it "1 - Al depositar 10, queda con 20." $ depósito 10 10 `shouldBe` 20
    it "2 - Al extraer 3, queda con 7." $ extracción 3 10 `shouldBe` 7
    it "3 - Al extraer 15, queda con 0." $ extracción 15 10 `shouldBe` 0
    it "4 - Con un upgrade, queda con 12." $ upgrade 10 `shouldBe` 12
    it "5 - Al cerrar la cuenta, queda con 0." $ cierreDeCuenta 10 `shouldBe` 0
    it "6 - Con queda igual, queda con 10." $ quedaIgual 10 `shouldBe` 10
    it "7 - Al depositar 1000, y luego tener un upgrade, queda con 1020." $ (upgrade.(depósito 1000)) 10 `shouldBe` 1020

type Nombre = String

data Usuario = Usuario {
  nombre :: Nombre,
  billetera :: Billetera
} deriving(Show,Eq)

nuevoNombre otroNombre usuario = usuario {nombre = otroNombre}
nuevaBilletera otroSaldo usuario = usuario {billetera = otroSaldo}

pepe = Usuario "José" 10
lucho = Usuario "Luciano" 2

pruebasConUsuarios = hspec $ do
  describe "Verificando usuarios" $ do
    it "8 - La billetera de pepe es de 10." $
      billetera pepe `shouldBe` 10
    it "9 - La billetera de Pepe, luego de un cierre de cuenta, es de 0." $
      (cierreDeCuenta . billetera) pepe `shouldBe` 0
    it "10 - La billetera de Pepe si le depositan 15, extrae 2, y tiene un Upgrade, es de 27.6." $
      (upgrade . extracción 2 . depósito 15 . billetera) pepe `shouldBe` 27.6

type Transacción = Usuario -> Evento
type Criterio = Usuario -> Usuario -> Bool

compararUsuario :: Criterio
compararUsuario usuarioAComparar usuario = nombre usuarioAComparar == nombre usuario

crearUnaNuevaTransacción :: Usuario -> Evento -> Transacción
crearUnaNuevaTransacción usuarioAComparar unEvento usuario
      | compararUsuario usuarioAComparar usuario = unEvento
      | otherwise = quedaIgual

transacción1 :: Transacción
transacción1 = crearUnaNuevaTransacción lucho cierreDeCuenta

transacción2 :: Transacción
transacción2 = crearUnaNuevaTransacción pepe (depósito 5)

pepe2 = Usuario "José" 20

tocoYMeVoy :: Evento
tocoYMeVoy = cierreDeCuenta . upgrade . depósito 15

ahorranteErrante :: Evento
ahorranteErrante = depósito 10 . upgrade . depósito 8 . extracción 1 . depósito 2 . depósito 1

transacción3 :: Transacción
transacción3 = crearUnaNuevaTransacción lucho tocoYMeVoy

transacción4 :: Transacción
transacción4 = crearUnaNuevaTransacción lucho ahorranteErrante

crearPagosEntreUsuarios :: Usuario -> Billetera -> Usuario -> Transacción
crearPagosEntreUsuarios usuarioExtracción cantidadDeUnidades usuarioDepósito usuario
        | compararUsuario usuarioExtracción usuario =  extracción cantidadDeUnidades
        | compararUsuario usuarioDepósito usuario = depósito cantidadDeUnidades
        | otherwise = quedaIgual

transacción5 :: Transacción
transacción5 = crearPagosEntreUsuarios pepe 7 lucho

pruebasConTransacciones = hspec $ do
  describe "Pruebas con las transacciones" $ do
    it "11 - La transacción 1 se aplica a pepe, esto produce el evento Queda igual, que si se aplica a una billetera de 20, debe dar una billetera con ese mismo monto." $
      transacción1 pepe 20 `shouldBe` 20
    it "12 - La transacción 2 se aplica a pepe, esto produce el evento depositar 5, que si se aplica a una billetera de 10, queda con 15." $
      transacción2 pepe 10 `shouldBe` 15
    it "13 - La transacción 2 se aplica a pepe2, esto produce un evento, que aplicado a una billetera de 50, queda con 55." $
      transacción2 pepe2 50 `shouldBe` 55
    it "14 - La transacción 3 se aplica a lucho. Ver cómo queda una billetera inicial de 10. Debería quedar con 0" $
      transacción3 lucho 10  `shouldBe` 0
    it "15 - La transacción 4 se aplica a lucho. Ver cómo queda una billetera inicial de 10. Debería quedar con 34" $
      transacción4 lucho 10  `shouldBe` 34
    it "16 - La transacción 5 se aplica a pepe, esto produce el evento de extracción 7. Al aplicarlo a una billetera de 10, debería dar una nueva billetera de 3." $
      transacción5 pepe 10 `shouldBe` 3
    it "17 - La transacción 5 se aplica a lucho, esto produce el evento de depósito 7. Al aplicarlo a una billetera de 10, debería dar una nueva billetera de 17." $
      transacción5 lucho 10 `shouldBe` 17

-- 2da Parte

impactar :: Transacción -> Usuario -> Usuario
impactar unaTransacción usuario = nuevaBilletera (unaTransacción usuario (billetera usuario)) usuario

pruebasConImpactar = hspec $ do
  describe "Pruebas con la nueva función impactar." $ do
    it "18 - Impactar la transacción 1 a Pepe. Debería quedar igual que como está inicialmente." $
      impactar transacción1 pepe `shouldBe` pepe
    it "19 - Impactar la transacción 5 a Lucho. Debería producir que Lucho tenga 9 monedas en su billetera." $
      impactar transacción5 lucho `shouldBe` nuevaBilletera 9 lucho
    it "20 - Impactar la transacción 5 y luego la 2 a Pepe. Eso hace que tenga 8 en su billetera." $
      (impactar transacción5.impactar transacción2) pepe `shouldBe` nuevaBilletera 8 pepe

type Bloque = [Transacción]

bloque1 :: Bloque
bloque1 = [transacción1, transacción2, transacción2, transacción2, transacción3, transacción4, transacción5, transacción3]

cómoQuedaSegún :: Bloque -> Usuario -> Usuario
cómoQuedaSegún unBloque usuario = foldr impactar usuario unBloque

quedanConUnSaldoDeAlMenos :: Billetera -> Bloque -> [Usuario] -> [Usuario]
quedanConUnSaldoDeAlMenos nroCréditos unBloque = filter ((>=nroCréditos).billetera.(cómoQuedaSegún unBloque))

másAdinerado :: Criterio
másAdinerado unUsuario otroUsuario = billetera unUsuario >= billetera otroUsuario

menosAdinerado :: Criterio
menosAdinerado unUsuario otroUsuario = billetera unUsuario <= billetera otroUsuario

quienEs :: Criterio -> Bloque -> Usuario -> Usuario -> Usuario
quienEs unCriterio unBloque unUsuario otroUsuario
        | unCriterio (cómoQuedaSegún unBloque unUsuario) (cómoQuedaSegún unBloque otroUsuario) = unUsuario
        | otherwise = otroUsuario

quienSería :: Criterio -> Bloque -> [Usuario] -> Usuario
quienSería unCriterio unBloque = foldl1 (quienEs unCriterio unBloque)

pruebasConBloque1 = hspec $ do
  describe "Pruebas con bloque1" $ do
    it "21 - A partir del bloque 1 y pepe, decir cómo queda el usuario con su nuevo saldo en su billetera. Debería quedar con su mismo nombre, pero con una billetera de 18." $
      cómoQuedaSegún bloque1 pepe `shouldBe` nuevaBilletera 18 pepe
    it "22 - A partir de pepe y lucho y el bloque1, solo pepe queda con un saldo de al menos 10." $
      quedanConUnSaldoDeAlMenos 10 bloque1 [pepe,lucho] `shouldBe` [pepe]
    it "23 - El más adinerado, cuando se les aplica el bloque1 a pepe y lucho es pepe" $
      quienSería másAdinerado bloque1 [pepe,lucho] `shouldBe` pepe
    it "24 - El menos adinerado, cuando se les aplica el bloque1 a pepe y lucho es lucho" $
      quienSería menosAdinerado bloque1 [pepe,lucho] `shouldBe` lucho

type BlockChain = [Bloque]

bloque2 :: Bloque
bloque2 = [transacción2,transacción2,transacción2,transacción2,transacción2]

blockChain1 :: BlockChain
blockChain1 = [bloque2,bloque1,bloque1,bloque1,bloque1,bloque1,bloque1,bloque1,bloque1,bloque1,bloque1]

crearBloqueCon :: BlockChain -> Bloque
crearBloqueCon unBlockChain = foldl (++) (head unBlockChain) (tail unBlockChain)

decidirEntreBloques :: Usuario -> Bloque -> Bloque -> Bloque
decidirEntreBloques unUsuario unBloque otroBloque
        | (billetera . cómoQuedaSegún unBloque) unUsuario < (billetera . cómoQuedaSegún otroBloque) unUsuario = unBloque
        | otherwise = otroBloque

elPeorBloque :: Usuario -> BlockChain -> Bloque
elPeorBloque unUsuario = foldl1 (decidirEntreBloques unUsuario)

cómoEstabaEn :: Int -> BlockChain -> Usuario -> Usuario
cómoEstabaEn ciertoPunto blockChain = cómoQuedaSegún (crearBloqueCon (take ciertoPunto blockChain))

pruebasConBlockChain = hspec $ do
  describe "Pruebas con BlockChain" $ do
    it "25 - El peor bloque para pepe de la BlockChain lo deja con un saldo de 18" $
      (billetera . cómoQuedaSegún (elPeorBloque pepe blockChain1)) pepe `shouldBe` 18
    it "26 - Pepe queda con 115 monedas cuando se le aplica la BlockChain" $
      (billetera . cómoQuedaSegún (crearBloqueCon blockChain1)) pepe `shouldBe` 115
    it "27 - Pepe queda con 51 monedas con los 3 primeros bloques de la BlockChain" $
      (billetera . cómoEstabaEn 3 blockChain1) pepe `shouldBe` 51
    it "28 - La suma de las billeteras de pepe y lucho cuando se les aplica la BlockChain es 115" $
      (sum . map billetera . map (cómoQuedaSegún (crearBloqueCon blockChain1))) [pepe,lucho] `shouldBe` 115

ejecutarTests = do
  pruebasConEventos
  pruebasConUsuarios
  pruebasConTransacciones
  pruebasConImpactar
  pruebasConBloque1
  pruebasConBlockChain
