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
	int beers_to_ask <- 4;
	int initial_sips <- 1;
	int sips_in_a_beer <- 3;
	int beer_limit <- 5;
// Shared knowledge by all agents that belong to the ontology:
// - Roles:
	string Fridge_role <- "Fridge";
	string Robot_role <- "Robot";
	string Super_role <- "Super";
	string Human_role <- "Human";
// - Actions to be used in the content of messages:
	string give_beer <- "Give_Beer";
	string bring_beer <- "Bring_Beer";
	string supply_beer <- "Suply_Beer";
// - Predicates to be used in the content of messages:
	string given_beer <- "Given_Beer";
	string brought_beer <- "Brought_Beer";
	string supplied_beer <- "Supplied_Beer";
	string no_beers <- "No_Beers";
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


species comprador skills: [fipa] control: simple_bdi {
	rgb owner_color;
	rgb thristy_color<- #red;
	rgb drinking_color <- #green;
	bool perceived <- false;
	// beliefs of the owner
	string sips <- "sips";
	string no_beer <- "no_beer";
	string no_drunk <- "no_drunk";
	string num_sips <- "number_sips";
	// desires of the owner
	predicate pedir_traer <- new_predicate("pedir_traer");
	predicate beber <- new_predicate("beber");
	//list<robot> my_robots;
	init {
		owner_color <- drinking_color;
		location <- {5, 5};
		predicate pred_no_drunk <- new_predicate(no_drunk); 
		do add_belief (pred_no_drunk);
		int attribute_value <- initial_sips;
		string attribute_name <- num_sips;
		predicate pred_sips <- new_predicate(sips,[attribute_name::attribute_value]);
		// 3 sorbos por cerveza
		do add_belief (pred_sips);
		do add_desire(beber);
		}
	
	aspect name:comprador_aspect {		
		draw geometry:circle(33.3/size) color:owner_color;
		// color will be red when the owner has no beer to drink
		// green when it is drinking
		point punto <- location;
		point punto2 <- {punto.x-1, punto.y+1};
		draw string("O") color: #black font:font("Helvetica", 15 , #plain) at: punto2;
	}
}

species vendedor skills: [fipa] control: simple_bdi {
	rgb owner_color;
	rgb thristy_color<- #red;
	rgb drinking_color <- #green;
	bool perceived <- false;
	// beliefs of the owner
	string sips <- "sips";
	string no_beer <- "no_beer";
	string no_drunk <- "no_drunk";
	string num_sips <- "number_sips";
	// desires of the owner
	predicate pedir_traer <- new_predicate("pedir_traer");
	predicate beber <- new_predicate("beber");
	//list<robot> my_robots;
	init {
		owner_color <- drinking_color;
		location <- {10*size-5, 10*size-5};
		predicate pred_no_drunk <- new_predicate(no_drunk); 
		do add_belief (pred_no_drunk);
		int attribute_value <- initial_sips;
		string attribute_name <- num_sips;
		predicate pred_sips <- new_predicate(sips,[attribute_name::attribute_value]);
		// 3 sorbos por cerveza
		do add_belief (pred_sips);
		do add_desire(beber);
		}
		
	aspect name:vendedor_aspect {		
		draw geometry:circle(33.3/size) color:owner_color;
		// color will be red when the owner has no beer to drink
		// green when it is drinking
		point punto <- location;
		point punto2 <- {punto.x-1, punto.y+1};
		draw string("O") color: #black font:font("Helvetica", 15 , #plain) at: punto2;
	}
}



experiment morebeers type: gui {
// parameters
	parameter "Initial sips of the human (positive integer):" var: initial_sips category: "Human";
	parameter "Total sips of a full beer (positive integer):" var: sips_in_a_beer category: "Human";
	parameter "Number of beers asked to be supplied by the Supermarket (positive integer):" var: beers_to_ask category: "Robot";
	parameter "Number of beers to get drunk (positive integer):" var: beer_limit category: "Robot";
	parameter "Initial beers in the fridge (positive integer):" var: initial_beers category: "Fridge";

	output {
		display my_display type: java2D {
			grid my_grid border: rgb("black");
			species comprador aspect:comprador_aspect;
			species vendedor aspect:vendedor_aspect;
			}
	}
}
	
