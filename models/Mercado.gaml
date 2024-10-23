/**
* Name: Mercado
* Based on the internal empty template. 
* Author: jorge
* Tags: 
*/
model Mercado

// torus:false means the extremes of the grid are not connected
global torus:false { 
  	int size <- 10;
	int cycles;
	int cycles_to_pause <- 5;
	bool game_over <- false;
	
	float step <- 10#mn;
    geometry shape <- square(20 #km);
	
//  Parameters setup:

	int n_compradores <- 3;
	int n_vendedores <- 5;
	list<string> productos_disponibles <- ["plátano", "cereza", "langosta", "manzana", "pera", "uva", "mango", "naranja"];
	
// Shared knowledge by all agents that belong to the ontology:
// - Roles:
	string Comprador_role <- "Comprador";
	string Vendedor_role <- "Vendedor";
// - Actions to be used in the content of messages:
	//string give_beer <- "Give_Beer";
// - Predicates to be used in the content of messages:
	string contraoferta_recibida <- "Contraoferta_Recibida";
	string oferta_recibida <-  "Oferta_Recibida";
	string inventario_recibido <-  "Inventario_Recibido";
	string aceptar_contraoferta <- "Aceptar_Contraoferta";
	string aceptar_compra <- "Aceptar_Compra";
	
	string localizacion_de_comprador <- "localizacion_de_comprador";
	string empty_mine_location <- "empty_mine_location";
	predicate localizacion_comprador <- new_predicate(localizacion_de_comprador) ;
// - Concepts to be linked with actions and predicates of the messages:
	//string num_beers <- "Number_Beers";
		 	
	init {
		// creation of the agents in the system
			//create species:df number:1;
			create species:comprador number:n_compradores;
			create species:vendedor number:n_vendedores;
	}
	reflex counting {
		cycles <- cycles+1;
	}
	// allow us to set recurrent pauses to observe step by step the behaviour of the system
//	reflex pausing when: cycles = cycles_to_pause {
//		write "pausing simulation";
//		cycles <- 0;
//		do pause;
//	}
	// to end the simulation
	reflex halting when: game_over {
		write "halting simulation";
		do die;
	}

}


// the grid of cells with diagonals as neighbors
//grid my_grid width:size height:size neighbors:8 {
//	
//}


// directory facilitator to allow agents meet first time from the role they used when they register
//species df {
//  list<pair> yellow_pages <- []; 
//  // to register an agent according to his role
//  bool register(string the_role, agent the_agent) {
//  	bool registered;
//  	add the_role::the_agent to: yellow_pages;
//  	return registered;
//  }
//  // to search agents accoding to the role
//  list search(string the_role) {
//  	list<agent> found_ones <- [];
//	loop i from:0 to: (length(yellow_pages)-1) {
//		pair candidate <- yellow_pages at i;
//		if (candidate.key = the_role) {
//			add item:candidate.value to: found_ones; }
//		} 
//	return found_ones;	
//	} 
//}

/*
 * Desires:
 * 	find_store, based on products you need to buy
 * 	ask_info
 * 	buy_product
 */

species comprador skills: [fipa, moving] control: simple_bdi {
	rgb owner_color;
	rgb thristy_color<- #red;
	rgb drinking_color <- #green;
	bool perceived <- false;
	
	float view_dist<-1000.0;
    float speed <- 2#km/#h;
    rgb my_color <- rnd_color(255);
    point target;
	
	// beliefs of the owner
	string amount_money <- "amount_money";
	int precio_producto <- 0;
	
	int presupuesto;
	map<string, int> necesidades;
	//list<string, int> productos_obtenidos;
    string estrategia_negociacion;
    bool en_coalicion;
    map<string, float> precio_conocido;
    
    map<string, int> vendedor_inventario;
    map<string, int> vendedor_precios;
    map <string, int> productos_comprar; // Productos que despues de preguntar al vendedor va a comprar el comprador
    map<string, int> precio_maximo;
    map <string, int> nuevos_precios;
	
	// desires of the comprador
	//TODO Igual habria que meter estos en global
	predicate negociar <- new_predicate("negociar");
	predicate comprar <- new_predicate("comprar");
	predicate preguntar <- new_predicate("preguntar");
	predicate buscar <- new_predicate("buscar") ;
	
	predicate interactuar_con_vendedor <- new_predicate("interactuar_con_vendedor");
	
	//list<robot> my_robots;
	
	message requestInfoFromVendedor;
	
	vendedor vendedor_actual;
	
	init {
		owner_color <- drinking_color;
		//location <- {5, 5};
		
		presupuesto <- rnd(100, 500); // Presupuesto entre 100 y 500
		int num_necesidades <- rnd(1, 4);
        //necesidades <- ["plátano", "cereza", "langosta"];
        list<string> productos_seleccionados <- shuffle(productos_disponibles)[0::num_necesidades];
        loop product over: productos_seleccionados {
	        int desired_quantity <- rnd(1, 5); // Assign a random desired quantity
	        necesidades[product] <- desired_quantity;
	        precio_maximo[product] <- rnd(20, 30);
	    }
	    
	    
        //estrategia_negociacion <- "agresiva"; // Puede ser "agresiva" o "conservadora"
        estrategia_negociacion <- one_of(["agresiva", "conservadora"]);
        en_coalicion <- false;
		
		write name + " Necesidades: " + necesidades;
		write name + " Presupuesto: " + presupuesto;
		do add_desire(buscar);
	}
	
	list<point> vendedores_visitados;
	
    
    perceive target: vendedor where (each.abierto) in: view_dist {
        focus id: localizacion_de_comprador var:location;
        ask myself {
        	bool nearby_visited_vendedor_found <- false;

			// Loop over the list of visited vendedores
			loop visited_location over: vendedores_visitados {
			    if (location distance_to visited_location < view_dist) {
			        nearby_visited_vendedor_found <- true;
			        break; // Exit the loop since we found a nearby visited vendedor
			    }
			}
        	
        	if (!nearby_visited_vendedor_found) {
        		
        		do remove_desire(buscar);
		    
		    	do add_desire(interactuar_con_vendedor);
	        }
        }

    }
    
    
	
	plan lets_wander intention: buscar {
		do wander;
    }
    
    
    plan interactuar_con_vendedor intention: interactuar_con_vendedor {
	    if (target = nil) {
	        // Collect possible vendedores from beliefs
	        list<point> vendedores_posibles <- get_beliefs_with_name(localizacion_de_comprador) collect (
	            point(get_predicate(mental_state(each)).values["location_value"])
	        );
	        list<point> vendedores_cerrados <- get_beliefs_with_name(empty_mine_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		
	        // Subtract vendedores already interacted with
	        vendedores_posibles <- vendedores_posibles - vendedores_cerrados; // Adjust this as per your code
	
	        if (empty(vendedores_posibles)) {
	            do remove_intention(interactuar_con_vendedor, true);
	            do add_desire(buscar); // Continue searching
	        } else {
	            target <- vendedores_posibles with_min_of (each distance_to self);
	        }
	    } else {
	        do goto target: target;
	        if (location = target) {
	            vendedor_actual <- vendedor first_with (each.location = location);
	            
	           	vendedores_visitados <+ location;
	            
	            //add vendedor_actual to: vendedores_interacted;
	            
	            do remove_desire(interactuar_con_vendedor);
	            do add_desire(preguntar);
	           
//	            if (empty(necesidades)) {
//	                write name + ": All needs fulfilled.";
//	                // Optionally, stop or add other desires
//	            } else {
//	                do add_desire(buscar); // Continue searching for remaining needs
//	            }
	            
	            target <- nil;
	            
	        }
	    }
	}
    
    
    
	// Enviamos al vendedor productos que le queremos comprar (productos_comprar)
	plan plan_comprar intention: comprar {
		//write name + ": Ahora toca comprar";
		
		//request al vendedor
		// tenemos el precio establecido en una variable
		list contenido <- [];
		string predicado <- oferta_recibida;
		list lista_conceptos <- [productos_comprar];
		pair contenido_pair <- predicado::lista_conceptos;
		add contenido_pair to:contenido;
		
		
		do start_conversation to: [vendedor_actual] protocol: 'fipa-request' performative: 'request' contents: contenido ;
	}
	
	plan plan_negociar intention: negociar {			
		list contenido <- [];
		string predicado <- contraoferta_recibida;
		list lista_conceptos <- [productos_comprar, nuevos_precios];
		pair contenido_pair <- predicado::lista_conceptos;
		add contenido_pair to:contenido;
		
		
		do start_conversation to: [vendedor_actual] protocol: 'fipa-request' performative: 'request' contents: contenido ;
	}
	
	plan plan_preguntar intention: preguntar {
		//vendedor_actual <- vendedor at_distance(1000000) at 0;
		//vendedor_actual <- vendedor first_with (target = each.location);
		write "AQUI: " + vendedor_actual;
		
		//do start_conversation to: [vendedor_actual] protocol: 'fipa-propose' performative: 'propose' contents: ['Go swimming?'] ;
		//do start_conversation to: [the_fridge] protocol: 'fipa-request' performative: 'request' contents: contenido ;	
		do start_conversation to: [vendedor_actual] protocol: 'no-protocol' performative: 'inform' contents: [''] ;
	}
	
	reflex receive_inform when: !empty(informs) {
		// Vendedor envia inventario y precio
		// write name + ' receive_inform';
//		loop i over: informs {
//			write name + ' receive_inform message with content: ' + string(i.contents);
//		}
		
		// Analizar productos y precios 
		message informInventarioDelVendedor <- informs at 0;
		
		list contentlist <- list(informInventarioDelVendedor.contents);
		map content_map <- contentlist at 0;
		pair content_pair <- content_map.pairs at 0;
		
		string predicado <- string(content_pair.key);
		list conceptos <- list(content_pair.value);
		
		vendedor_inventario <- conceptos[0];
		vendedor_precios <- conceptos[1];
		
		do remove_desire(preguntar);
		
		if (empty(necesidades)) {//TODO añadir que se acaba de comprar cuando se queda sin dinero o necesidades
            write name + ": No needed products available from vendedor.";
            // do add_desire(buscar); 
        } else {
        	float total_cost <- 0.0;
        	
        	write "AQUI:"+necesidades.keys;
	        loop product over: necesidades.keys {
	            int desired_quantity <- necesidades[product];
	
	            // Check if the product is available in the vendedor's inventory
	            if (vendedor_inventario contains_key product) {
	                int available_quantity <- vendedor_inventario[product];
	                int price <- vendedor_precios[product];
	
	                // Determine the maximum quantity we can afford and that is available
	                int max_affordable_quantity <- presupuesto div price;
	                int quantity_to_buy <- min(desired_quantity, max_affordable_quantity, available_quantity);
	
	                if (quantity_to_buy > 0) {
	                    productos_comprar[product] <- quantity_to_buy;
	                    total_cost <- total_cost + (price * quantity_to_buy);
	                }
	            } else {
	                write name + ": Product " + product + " not available from vendedor.";
	            }
	        }
	
	        // Decide whether to make a counteroffer if total_cost exceeds presupuesto
	        bool contraofertar <- false;
		
			loop product over: productos_comprar.keys {
				if vendedor_precios[product] > precio_maximo[product] {
					contraofertar <- true;
					nuevos_precios[product] <- precio_maximo[product];
				} else {
					nuevos_precios[product] <- vendedor_precios[product];
				}
			}
	        
	        //if (total_cost > presupuesto) {
	        if (contraofertar) {
	            write name + ": Total cost exceeds presupuesto. Considering counteroffer.";
	            do add_desire(negociar);
	        } else if (!empty(productos_comprar)) {
	        	write name + ": Va a comprar lo siguente: " + productos_comprar;
	            do add_desire(comprar);
	        } else {
	            write name + ": Cannot buy any products at current prices.";
	            do add_desire(buscar); // Go back to searching
	        }
        }
		
		
		
		// Igual añadir un belief del precio??
		
	}
	
	reflex read_accept_proposals when: !(empty(accept_proposals)) {
		//write name + ' receives accept_proposal messages';
		loop i over: accept_proposals {
			write name + ' accept_proposal message with content: ' + string(i.contents);
		}
	}
	
	reflex receive_agree when: !empty(agrees) {
		//write name + "receive_agree: Vendedor esta de acuerdo con mi contraoferta";
		
		// Ahora toca comprar
		// Actualizar nuevo precio del producto
		message agree_received <- agrees at 0;
		
		loop i over: agrees {
			write name + ' receive_agree message with content: ' + string(i.contents);
		}
		write agree_received;
		
		if (agree_received.contents[0] = aceptar_compra) {
			loop product over: productos_comprar.keys {
	            int quantity_bought <- productos_comprar[product];
	            int price <- vendedor_precios[product];
	
	            // Deduct from presupuesto
	            presupuesto <- presupuesto - (price * quantity_bought);
	
	            // Update necesidades
	            int remaining_quantity <- necesidades[product] - quantity_bought;
	            if (remaining_quantity > 0) {
	                necesidades[product] <- remaining_quantity;
	            } else {
	                necesidades[] >> product;
	            }
	            // write name + " Producto: " + product + " remaining_quantity: " + remaining_quantity;
	            write name + " Necesidades acutalizadas: " + necesidades;
	        }
	
			productos_comprar[] >>- productos_comprar.keys; // Vaciamos los productos a comprar
	        write name + ": Purchase successful. Remaining presupuesto: " + string(presupuesto);
	        // Decide next action
	        if (empty(necesidades)) {
	            write name + ": All needs fulfilled.";
	            // Optionally, stop or add other desires
	        } else {
	            do add_desire(buscar); // Continue searching for remaining needs
	        }
	        
	        do remove_desire(comprar);
			
		}
		
		if (agree_received.contents[0] = aceptar_contraoferta) {
			write "SAKLDjlkjfslf";
			loop product over: productos_comprar.keys {
	            int quantity_bought <- productos_comprar[product];
	            int price <- nuevos_precios[product];
	
	            // Deduct from presupuesto
	            presupuesto <- presupuesto - (price * quantity_bought);
	
	            // Update necesidades
	            int remaining_quantity <- necesidades[product] - quantity_bought;
	            if (remaining_quantity > 0) {
	                necesidades[product] <- remaining_quantity;
	            } else {
	                necesidades[] >> product;
	            }
	            // write name + " Producto: " + product + " remaining_quantity: " + remaining_quantity;
	            write name + " Necesidades acutalizadas: " + necesidades;
	        }
	
			productos_comprar[] >>- productos_comprar.keys; // Vaciamos los productos a comprar
			nuevos_precios[] >>- nuevos_precios.keys;
	        write name + ": Purchase successful. Remaining presupuesto: " + string(presupuesto);
	        // Decide next action
	        if (empty(necesidades)) {
	            write name + ": All needs fulfilled.";
	            // Optionally, stop or add other desires
	        } else {
	            do add_desire(buscar); // Continue searching for remaining needs
	        }
	        
	        do remove_desire(comprar);
	        
	        
			
			
			
			do remove_desire(negociar);
			// do add_desire(comprar);
		}
		
		
	}
	
	
	reflex receive_failure when: !empty(failures) {
		message failureFromFridge <- failures[0];
		write name + " failure: " + failureFromFridge;	
		do remove_desire(negociar);
	}
	
	reflex receive_refuse when: !empty(refuses) {
		message failureFromFridge <- refuses at 0;
		//refuses[] >> 0;
		refuses >>- failureFromFridge;
		//remove refuses;
		loop i over: refuses {
			//write name + ' receive_agree message with content: ' + string(i.contents);
			//write name + " refuse: message with content " + failureFromFridge;
		}
		write 'Robot receives a failure message from the Fridge with content ' + failureFromFridge.contents;
		
		do remove_desire(negociar);
		do remove_desire(comprar);
		do add_desire(buscar);
	}
	
	
//	aspect name:comprador_aspect {		
//		draw geometry:circle(33.3/size) color:owner_color;
//		// color will be red when the owner has no beer to drink
//		// green when it is drinking
//		point punto <- location;
//		point punto2 <- {punto.x-1, punto.y+1};
//		draw string("C") color: #black font:font("Helvetica", 15 , #plain) at: punto2;
//	}
	aspect default {
      draw circle(200) color: my_color border: #black;
      draw circle(view_dist) color: my_color border: #black wireframe: true;
    }
}









species vendedor skills: [fipa] control: simple_bdi {
//	rgb owner_color;
//	rgb thristy_color<- #red;
//	rgb drinking_color <- #green;
	bool perceived <- false;
	
	// beliefs of the owner
	
	map<string, int> inventario;
    map<string, int> precios;
    string estrategia_precio;
    list ventas_realizadas;
    int dinero;
    
	bool abierto <- true;
	// desires of the owner
	//predicate pedir_traer <- new_predicate("pedir_traer");
	
	//list<robot> my_robots;
	init {
		//owner_color <- drinking_color;
		//location <- {10*size-5, 10*size-5};
		
		
		/*
		 * Opciones:
		 * 	Mercado tiene un solo producto
		 * 	Mercado tiene varios productos
		 * 
		 * 	Vendedor detecta mercado en base al producto que pasa cerca de su zona de vision (estilo mineros)
		 * 	Vendedor sabe de primeras donde tiene que ir para comprar cierto producto. -> En este caso veo mas que cada Mercado
		 * 				venda solo un producto
		 */
//		inventario <- ["plátano"::50, "cereza"::100, "langosta"::5];
//        precios <- ["plátano"::2.0, "cereza"::1.50, "langosta"::200.0];
        
        int num_productos <- rnd(1, length(productos_disponibles)); // Random number of products to sell
        list<string> selected_products <- shuffle(productos_disponibles)[0::num_productos];

        loop product over: selected_products { 
        	//location <- {5, 5};
            int cantidad <- rnd(10, 100); // Random quantity between 10 and 100
            int precio <- rnd(20, 30); // Random price between 1.0 and 30.0

            inventario[product] <- cantidad;
            precios[product] <- precio;
        }
        
        estrategia_precio <- "dinamica"; // Puede ser "fija" o "dinamica"
        
        write name + " Inventario: " + inventario + " Precios: " + precios;
		/* 
		predicate pred_no_drunk <- new_predicate(no_drunk); 
		do add_belief (pred_no_drunk);
		int attribute_value <- initial_sips;
		string attribute_name <- num_sips;
		predicate pred_sips <- new_predicate(sips,[attribute_name::attribute_value]);
		// 3 sorbos por cerveza
		do add_belief (pred_sips);
		do add_desire(beber);*/
		}
		
		
	// Comprador pregunta info productos
	reflex receive_inform when: !empty(informs) {
		write name + ' receive_inform: Me estan preguntando por mis productos';
		message informDelComprador <- informs at 0;
		
		// Enviar listado de productos y precio
		list contenido <- [];
		string predicado <- inventario_recibido;
		list lista_conceptos <- [inventario, precios];
		pair contenido_pair <- predicado::lista_conceptos;
		add contenido_pair to:contenido;
		
		do inform message: informDelComprador contents: contenido ;
	}
	
//	reflex accept_proposal when: !(empty(proposes)) {
//		write name + ' accept_proposal';
//		message proposalFromInitiator <- proposes at 0;
//		
//		do accept_proposal message: proposalFromInitiator contents: ['OK! It \'s hot today!'] ;
//	}
	
	
	reflex receive_requests when: !(empty(requests)) {
		message requestContraofertaDelComprador <- requests at 0;
		
		list contentlist <- list(requestContraofertaDelComprador.contents);
		map content_map <- contentlist at 0;
		pair content_pair <- content_map.pairs at 0;
		string predicado <- string(content_pair.key);
		list conceptos <- list(content_pair.value);
		
		if (predicado = contraoferta_recibida) {
			write name + ' receive_requests: Recibida contraoferta del pescado: ' + conceptos[0] + conceptos[1];
			
			map <string, int> precios_comprador <- conceptos[1];
			map <string, int> productos <- conceptos[0];
			
			bool aceptar_contra <- true;
			loop producto over: precios_comprador.keys {
				if precios[producto] > precios_comprador[producto] + 3 {
					aceptar_contra <- false;
				}
			}
			
			if aceptar_contra {//Contaoferta
				bool exito_compra <- true;
		       
		        int posible_dinero <- 0;
	
		        loop product over: productos.keys {
		            int requested_quantity <- productos[product];
		            if (inventario contains_key product and inventario[product] >= requested_quantity) {
		                // Actualizar inventario
		                inventario[product] <- inventario[product] - requested_quantity;
		                
		                if (inventario[product] = 0) {		             
			                inventario[] >> product;
			            }
			            
			            posible_dinero <- posible_dinero + precios_comprador[product] * requested_quantity;
		            
		                // Optionally, update sales records
		                write name + ": Sold " + string(requested_quantity) + " units of " + product + " to " + string(requestContraofertaDelComprador.sender);
		            } else {
		                // Not enough stock
		                write "HA habido fail";
		                write name + ": Not enough stock of " + product + " for " + string(requestContraofertaDelComprador.sender);
		                exito_compra <- false;
		                // Send failure message
		                do refuse message: requestContraofertaDelComprador contents: ["Insufficient stock for " + product];
		                break; // Exit the loop if any product is unavailable
		            }
		        }
		
		        if (exito_compra) {
		            // Send confirmation
		            // do inform to: [comprador_agent] contents: ["Purchase confirmed"];
					write "NO HA habido fail";
		            
		            dinero <- dinero + posible_dinero;
		            write name + " Dinero actualizado: " + dinero;      
					// Restar el producto
					do agree message: requestContraofertaDelComprador contents: [aceptar_contraoferta];
		        }
			}
			else {
			
				do refuse message: requestContraofertaDelComprador contents: ["Insufficient stock"];
				write "Contraoferta rechazada";
			}
			
		}
		
		if (predicado = oferta_recibida) {//Compra
			// Checkear es el valor esperado
			write name + ": Recibida oferta de compra de " + string(requestContraofertaDelComprador.sender);
			
			
			// Procesar la compra
	        bool exito_compra <- true;
	        map <string, int> productos <- conceptos[0];
	        
	        int posible_dinero <- 0;

	        loop product over: productos.keys {
	            int requested_quantity <- productos[product];
	            if (inventario contains_key product and inventario[product] >= requested_quantity) {
	                // Actualizar inventario
	                inventario[product] <- inventario[product] - requested_quantity;
	                
	                if (inventario[product] = 0) {		             
		                inventario[] >> product;
		            }
		            
		            posible_dinero <- posible_dinero + precios[product] * requested_quantity;
	            
	                // Optionally, update sales records
	                write name + ": Sold " + string(requested_quantity) + " units of " + product + " to " + string(requestContraofertaDelComprador.sender);
	            } else {
	                // Not enough stock
	                write name + ": Not enough stock of " + product + " for " + string(requestContraofertaDelComprador.sender);
	                exito_compra <- false;
	                // Send failure message
	                do refuse message: requestContraofertaDelComprador contents: ["Insufficient stock for " + product];
	                break; // Exit the loop if any product is unavailable
	            }
	        }
	
	        if (exito_compra) {
	            // Send confirmation
	            // do inform to: [comprador_agent] contents: ["Purchase confirmed"];
	            
	            dinero <- dinero + posible_dinero;
	            write name + " Dinero actualizado: " + dinero;      
				// Restar el producto
				do agree message: requestContraofertaDelComprador contents: [aceptar_compra];
	        }
			
			
		}
		
	
	}
	
	//TODO Si vendedor vende todo cierra el puesto
		
//	aspect name:vendedor_aspect {		
//		draw geometry:circle(33.3/size) color:owner_color;
//		// color will be red when the owner has no beer to drink
//		// green when it is drinking
//		point punto <- location;
//		point punto2 <- {punto.x-1, punto.y+1};
//		draw string("V") color: #black font:font("Helvetica", 15 , #plain) at: punto2;
//	}
	aspect default {
      draw square(1000) color: #black ;
    }
}



//experiment morebeers type: gui {
//// parameters
//	//parameter "Initial sips of the human (positive integer):" var: initial_sips category: "Human";
//
//	output {
//		display my_display type: java2D {
//			grid my_grid border: rgb("black");
//			species comprador aspect:comprador_aspect;
//			species vendedor aspect:vendedor_aspect;
//			}
//	}
//}

experiment MercadoBdi type: gui {

    output {
        display map type: 3d {
            species vendedor ;
            species comprador;
        }
        
//        display chart type: 2d {
//			chart "Money" type: series {
//				datalist legend: miner accumulate each.name value: miner accumulate each.gold_sold color: miner accumulate each.my_color;
//			}
//		}
        
    }
}
	
