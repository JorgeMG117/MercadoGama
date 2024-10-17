/**
* Name: Mercado
* Based on the internal empty template. 
* Author: jorge
* Tags: 
*/


model Mercado

/* Insert your model definition here */

// torus:false means the extremes of the grid are not connected
global torus:false { 
  	int size <- 10;
	int cycles;
	int cycles_to_pause <- 5;
	bool game_over <- false;
//  Parameters setup:
	int initial_beers <- 1;
	int n_compradores <- 1;
	int n_vendedores <- 1;
// Shared knowledge by all agents that belong to the ontology:
// - Roles:
	string Comprador_role <- "Comprador";
	string Vendedor_role <- "Vendedor";
// - Actions to be used in the content of messages:
	//string give_beer <- "Give_Beer";
// - Predicates to be used in the content of messages:
	//string given_beer <- "Given_Beer";
// - Concepts to be linked with actions and predicates of the messages:
	string num_beers <- "Number_Beers";
		 	
	init {
		// creation of the agents in the system
			create species:df number:1;
			create species:comprador number:1;
			create species:vendedor number:1;
	}
	reflex counting {
		cycles <- cycles+1;
	}
	// allow us to set recurrent pauses to observe step by step the behaviour of the system
	reflex pausing when: cycles = cycles_to_pause {
		write "pausing simulation";
		cycles <- 0;
		do pause;
	}
	// to end the simulation
	reflex halting when: game_over {
		write "halting simulation";
		do die;
	}

}


// the grid of cells with diagonals as neighbors
grid my_grid width:size height:size neighbors:8 {
	
}


// directory facilitator to allow agents meet first time from the role they used when they register
species df {
  list<pair> yellow_pages <- []; 
  // to register an agent according to his role
  bool register(string the_role, agent the_agent) {
  	bool registered;
  	add the_role::the_agent to: yellow_pages;
  	return registered;
  }
  // to search agents accoding to the role
  list search(string the_role) {
  	list<agent> found_ones <- [];
	loop i from:0 to: (length(yellow_pages)-1) {
		pair candidate <- yellow_pages at i;
		if (candidate.key = the_role) {
			add item:candidate.value to: found_ones; }
		} 
	return found_ones;	
	} 
}

/*
 * Desires:
 * 	find_store, based on products you need to buy
 * 	ask_info
 * 	buy_product
 */

species comprador skills: [fipa] control: simple_bdi {
	rgb owner_color;
	rgb thristy_color<- #red;
	rgb drinking_color <- #green;
	bool perceived <- false;
	// beliefs of the owner
	string amount_money <- "amount_money";
	// desires of the comprador
	predicate negociar <- new_predicate("negociar");
	predicate comprar <- new_predicate("comprar");
	predicate preguntar <- new_predicate("preguntar");
	//list<robot> my_robots;
	
	message requestInfoFromVendedor;
	
	list<string> my_products;
	vendedor vendedor_actual;
	
	init {
		owner_color <- drinking_color;
		location <- {5, 5};
		

		//do add_desire(comprar);
		do add_desire(preguntar);
	}
		
	reflex receive_inform when: !empty(informs) {
		write name + ' receive_inform';
		loop i over: informs {
			write 'accept_proposal message with content: ' + string(i.contents);
		}
		
		do remove_desire(preguntar);
		// Igual añadir un belief del precio??
		do add_desire(negociar);
	}
	
	plan plan_comprar intention: comprar {
		
		
	}
	
	plan plan_negociar intention: negociar {
		// tengo en una variable el precio que me han propuesto
		// valoro si quiero hacer una contraoferta
		int precio_recibido <- 30;
		int precio_contraoferta <- 25;
		write name + " proponiendo contraoferta: " + precio_contraoferta;
		
		//si quiero
			//escribir proposal (proponer_contraoferta)
		comprador comprador_actual <- comprador at_distance(10000000) at 0;
		do start_conversation to: [comprador_actual] protocol: 'fipa-propose' performative: 'propose' contents: ['Go swimming?'] ;
	}
	
	plan plan_preguntar intention: preguntar {
		vendedor_actual <- vendedor at_distance(1000000) at 0;
		
		//do start_conversation to: [vendedor_actual] protocol: 'fipa-propose' performative: 'propose' contents: ['Go swimming?'] ;
		//do start_conversation to: [the_fridge] protocol: 'fipa-request' performative: 'request' contents: contenido ;	
		do start_conversation to: [vendedor_actual] protocol: 'no-protocol' performative: 'inform' contents: [''] ;
	}
	
	reflex read_accept_proposals when: !(empty(accept_proposals)) {
		write name + ' receives accept_proposal messages';
		loop i over: accept_proposals {
			write 'accept_proposal message with content: ' + string(i.contents);
		}
	}
	
	aspect name:comprador_aspect {		
		draw geometry:circle(33.3/size) color:owner_color;
		// color will be red when the owner has no beer to drink
		// green when it is drinking
		point punto <- location;
		point punto2 <- {punto.x-1, punto.y+1};
		draw string("C") color: #black font:font("Helvetica", 15 , #plain) at: punto2;
	}
}

species vendedor skills: [fipa] control: simple_bdi {
	rgb owner_color;
	rgb thristy_color<- #red;
	rgb drinking_color <- #green;
	bool perceived <- false;
	
	// beliefs of the owner
	string inventario <- "pescado";

	// desires of the owner
	//predicate pedir_traer <- new_predicate("pedir_traer");
	
	//list<robot> my_robots;
	init {
		owner_color <- drinking_color;
		location <- {10*size-5, 10*size-5};
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
		write name + ' receive_inform';
		message informDelComprador <- informs at 0;
		do inform message: informDelComprador contents: ['Precio del pescado: 30!'] ;
	}
	
	reflex accept_proposal when: !(empty(proposes)) {
		write name + ' accept_proposal';
		message proposalFromInitiator <- proposes at 0;
		
		do accept_proposal message: proposalFromInitiator contents: ['OK! It \'s hot today!'] ;
	}
	
		
	aspect name:vendedor_aspect {		
		draw geometry:circle(33.3/size) color:owner_color;
		// color will be red when the owner has no beer to drink
		// green when it is drinking
		point punto <- location;
		point punto2 <- {punto.x-1, punto.y+1};
		draw string("V") color: #black font:font("Helvetica", 15 , #plain) at: punto2;
	}
}



experiment morebeers type: gui {
// parameters
	//parameter "Initial sips of the human (positive integer):" var: initial_sips category: "Human";

	output {
		display my_display type: java2D {
			grid my_grid border: rgb("black");
			species comprador aspect:comprador_aspect;
			species vendedor aspect:vendedor_aspect;
			}
	}
}
	
