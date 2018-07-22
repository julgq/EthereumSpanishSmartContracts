pragma solidity ^0.4.24;

contract Subasta {
    
    // Direccion Publica de Ethereum de quien recibira los fondos de la subasta
    address public beneficiario;
    
    // Tiempo que permanecera la subasta activa, se escribe en segundos
    uint public subastaTermina;
    
    // Direccion publica de Ethereum del mejor ofertante hasta el momento
    address public mejorOfertante;
    
    // Mejor oferta en wei - unidad minima de ether
    uint public mejorOferta;
    
    /* Mapa de direcciones publicas de Ethereum que ofertaron y su oferta es menor a la ganadora, 
    los fondos se retornaran. */
    mapping(address => uint) reembolsosPendientes;
    
    // Asignar true significa que la subasta ha finalizado
    bool estatusSubasta;
    
    // Evento para generar log, cuando la oferta se eleve
    event SubirMayorOferta(address ofertante, uint monto);
    
    // Evento para generar log, cuando la subasta haya finalizado
    event FinalizarSubasta(address ganador, uint monto);
   
    
    /* 
     * Definicion constructor Subasta:
     * _tiempoSubasta - Cantidad de segundos que permancera activa la subastaTermina
     * _beneficiario - Clave publica de beneficiario, quien recibe los fondos cuando la subasta FinalizarSubasta
    */ 
    constructor(uint _tiempoSubasta, address _beneficiario) public {
        
        // beneficiario es igual a la direccion wallet que entra en el constructor 
        beneficiario = _beneficiario;
        
        // el tiempo que entra en el constructor es el asignado a el tiempo que permanecera activa la subasta
        subastaTermina = now + _tiempoSubasta;
    }
    
    
    /*
     * Definicion: ofertar()
     * No requiere argumentos de entrada
     * El keyword: payable es requerido para poder recibir Ether dentro de la funcion
    */
    
    function ofertar() public payable {
        
        // Validar si la subasta no ha finalizado, si esta activa pasa este require
        require(
            now <= subastaTermina,
            'La subasta ha finalizado.'
        );
        
        
        /* 
         *   Validar si la oferta es mayor que la mejorOferta, 
         *   si es mayor entonces pasa este requiere, si es menor se retorna el Ether 
        */
        require(
            msg.value > mejorOferta,
            'Existe una oferta mas alta'
        );
        
        if(mejorOferta != 0){
            
            /* Advertencia de Seguridad:
             * Retornar dinero del modo mejorOfertante.send(mejorOferta); es un riesgo de seguridad,
             * porque podria ejecutar un contrato no confiable,
             * siempre es mas seguro dejar que los destinatarios retiren su dinero ellos mismos.
            */
            
            // insertar direccion de ofertante y el monto del retorno
            // Cuando se ejecute la funcion retirar() se retorna el Ether enviado a la subasta
            reembolsosPendientes[mejorOfertante] += mejorOferta;
        }
        
        
        /*
         * Pasando todas las validaciones, ahora asignamos el nuevo mejorOfertante
         * msg.sender = direccion publica del ofertante
         * msg.value = valor en weit del ofertante
        */
        
        mejorOfertante = msg.sender;
        mejorOferta = msg.value;
        
        // Emitir evento SubirMayorOferta
        emit SubirMayorOferta(msg.sender, msg.value);
        
    }
    
    /*
     * Definicion retirar()
     * Funcion que regresa los fondos a los ofertantes
     * Esta funcion debe ser llamada por cada ofertante
    */
    function retirar() public returns (bool) {
        
        // Identificar cual es monto por reembolsar de quien solicita la funcion
        uint monto = reembolsosPendientes[msg.sender];
        
        // Si el monto es mayor a 0 entonces:
        if (monto > 0) {
            // Se le asigna 0 al reembolso en la lista de pendientes a reembolsar.
            reembolsosPendientes[msg.sender] = 0;
            
            // Si no se logra reembolsar correctamente entonces:
            if (!msg.sender.send(monto)){
                // Se vulve asignar el monto de reembolso a su direccion
                // No es necesario llamar a throw para lanzar excepciones, solo con reasignar el monto a su dueño 
                reembolsosPendientes[msg.sender] = monto;
                return false;
            }
        }
        
        return true;
        
    }
    
     /*
      * Definicion finalizrSubasta()
      * Funcion que finaliza la subasta
      * 
    */
    function finalizarSubasta() public {
        require(now >= subastaTermina, 'Subasta aún no terminada.');
        require(!estatusSubasta, 'estatusSubasta ya ha sido llamado, ya se le ha asignado true');
        
        estatusSubasta = true;
        
        // Emitir evento en log: que la subasta ha finalizado
        emit FinalizarSubasta(mejorOfertante, mejorOferta);
        
        // Enviar fondos al beneficiario ahora que la subasta termino.
        beneficiario.transfer(mejorOferta);
    }
    
    
    
    
    
    
}