const admin = require("firebase-admin");
const { setGlobalOptions } = require("firebase-functions/v2");

// Inicializa o Firebase Admin SDK uma única vez.
admin.initializeApp();

// Define a região global para todas as funções de 2ª geração.
// Isso evita ter que declarar a região em cada função individualmente.
setGlobalOptions({ region: "southamerica-east1" });

// O código abaixo carrega os módulos 'events', 'gameplay', 'admin', e 'wallet',
// e copia todas as funções exportadas por eles para o 'exports' principal do projeto.
// Isso faz com que o Firebase reconheça todas as suas funções.
Object.assign(exports,
    require("./events"),
    require("./gameplay"),
    require("./admin"),
    require("./wallet")
);