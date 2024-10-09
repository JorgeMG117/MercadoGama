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
			create species:robot number:1;
			create species:owner number:1;
			create species:supermarket number:1;
			create species:fridge number:1;
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