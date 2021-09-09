/*========================================================================================================================================*/
//Andalib Shams
//CE 650D
//Activity 1


//2-25-21
/*========================================================================================================================================*/


int t = 0;
final int simulation_time = 4500; // total simulation run time

int link1_output_counter = 0;// this have been used to check vehicle output in link1 cell 15

// It has been assumed that each cell can contain at most 4 vehicles. 
final int N_max = 4; 

/*------------------------------------------------------------------------------------------------------------*/
// a simple signalized intersection have been implemented. 
final int cycle_length = 120;
final int signal_loc = 65; // the position of the intersection in major arterial (cell value in major link)
/*------------------------------------------------------------------------------------------------------------*/


// create objects for class link. (link here is similar to vissim link)
link link1, link2, link3; 

PFont myfont;

//printing stuff
PrintWriter output;
String tempOut = "";

/*========================================================================================================================================*/
  
void setup(){
  frameRate(500); // frameRate per second
  
  size(1800, 600);
  myfont = loadFont("TimesNewRomanPSMT-10.vlw");
  output = createWriter("data.csv");
 
  /*------------------------------------------------------------------------------------------------------------*/
  // initialize links
  
  // here I have defined three links. The first one link1 is the major link with 100 cells, 1000 veh/hr and Q max =2 
  // link 2 is a minor road with 25 cell, 1000 vehicle/ hr volume and Q max = 1,
  // link 2 merged with link 1 at link1 cell number 65 (signal_loc variable) and formed a signalized intersection
  
  // link 3 is a minor road with 20 cell, 800 vehicle/ hr volume and Q max = 1,
  // link 3 merged with link 1 at link1 cell number 15 and formed a non-signalized intersection
  
  link1 = new link(100, 1200, 2); // new link(number of cells, volume (veh/hr), Q max)
  link1.cell_initialization();
  
  link2 = new link(25, 1000, 1);
  link2.cell_initialization();
  
  link3 = new link(20, 800, 1);
  link3.cell_initialization();
  
  // In link 1 from 20 to 35, Q value is updated to 1. (previously it was 1)
  link1.Q_change(1, 20, 35); 
}
  
/*========================================================================================================================================*/
  
void draw(){
  t++;
  if(t>=simulation_time) {
    print(link1_output_counter);
    noLoop(); // stop the simulation
  }
  background(255);
  
  fill(0); // set fill to black - text will be in black
  textFont(myfont, 14);
  text("time = " + t, 10, 10);
  text("Cycle Second = " + t%cycle_length, 10, 30);

  /*------------------------------------------------------------------------------------------------------------*/
  // a simple signal control logic
  if (t%cycle_length>60)  link1.Q_change(0, signal_loc, signal_loc+1);
  else link1.Q_change(link1.Q_max, signal_loc, signal_loc+1);
  
  
  /*------------------------------------------------------------------------------------------------------------*/
  //calculate y_i(t) 
  link1.calculate_yt();
  
  
  // update y if there is input from another link
  
  // link.cell.update_yt_source(int previous_n, int previous_q )
  
  // if there is input from any other link, we need to update the y. and also we have to store the difference between y_curr - y_prev
  // here un** = y_curr - y_prev;
  
  //un12 is for link 1 and link 2
  //un13 is for link 1 and link 3
  
  int un12 = 0, un13; 
  
  if (t%cycle_length>60)  {
    un12 = link1.cell_[signal_loc+1].update_yt_source(link2.cell_[link2.num_cell - 1].n, link2.cell_[link2.num_cell - 1].Q);
    // printing for debugging purpose
    //print(link1.cell_[signal_loc].n + " " + link1.cell_[signal_loc+1].n+" "+link1.cell_[signal_loc+2].n+" "+ un12+" "+link2.cell_[link2.num_cell - 1].n + "\n");  
  }
  
  un13 = link1.cell_[15].update_yt_source(link3.cell_[link3.num_cell - 1].n, link3.cell_[link3.num_cell - 1].Q);
  
  // 
  link2.cell_[link2.num_cell - 1].update_n_sink(un12);
  link3.cell_[link3.num_cell - 1].update_n_sink(un13);
  
  /*------------------------------------------------------------------------------------------------------------*/
  // calculate yt
  link2.calculate_yt();
  link3.calculate_yt();
  
  /*------------------------------------------------------------------------------------------------------------*/
  // calculate n for each cell in each link
  // here 0 means last cell will be cleared. 1 means last cell will store vehicle.
  link1.calculate_n(0);
  link2.calculate_n(1);
  link3.calculate_n(1);
  
  /*------------------------------------------------------------------------------------------------------------*/
  
  if(t>900) link1_output_counter+=link1.cell_[14].y;
  /*------------------------------------------------------------------------------------------------------------*/
  // For visualization. 
  
  // creats a small green and red box at signal location
  
  if(t%cycle_length>60) fill(#FF0000);
  else fill(#008000);
  rect(1132,30,10,10);
  
  if(t%cycle_length>60) fill(#008000);
  else fill(#FF0000);
  rect(1149,67,10,10);

  /*------------------------------------------------------------------------------------------------------------*/
  // draw and updates the 
  
  draw_simulation(link1.cell_, link1.num_cell, 10, 50, 17, 0);
  draw_simulation(link2.cell_, link2.num_cell, 1132, 50, 17, 2);
  draw_simulation(link3.cell_, link3.num_cell, 265, 50, 17, 2);

  /*------------------------------------------------------------------------------------------------------------*/
  // printing output to a csv file
  tempOut = "" + t;
  for (int i=0; i<link1.num_cell; i++) {
    tempOut = tempOut + "," + link1.cell_[i].n;
  }

  output.println(tempOut);
  output.flush();
}

/*========================================================================================================================================*/


class Cell{
  private int n, N, Q, y, y1, y2, nextn;
  /*------------------------------------------------------------------------------------------------------------*/
  public Cell(int Q_){
    n = 0;
    N = N_max; // assumed that N_max would be a constant
    Q = Q_;
  }
  
  /*------------------------------------------------------------------------------------------------------------*/
  // If there is input from another link, (or merging situation) we need to update the y value.
  // As there can be flow from previous cell, N-n is updated to N-n-y.

  public int update_yt_source(int flow, int Q_){
    y2 = min(flow, Q_, N-n-y); 
    y += y2;
    return y2;
  }
  /*------------------------------------------------------------------------------------------------------------*/
  //When a link merge with another and vehicle flow from it, we need to subtract that vehicle
  
  public void update_n_sink(int un_){
    n = n- un_;
  }
}

/*========================================================================================================================================*/
  
  
class link{
  private int num_cell, volume, Q_max;
  
  public Cell[] cell_;
  
  
  /*------------------------------------------------------------------------------------------------------------*/
  // link constructor
  public link(int num_cell_, int volume_, int Q_max_){
    num_cell = num_cell_;
    volume = volume_;
    Q_max = Q_max_;
    cell_ = new Cell[num_cell];
  } 
  
  
  /*------------------------------------------------------------------------------------------------------------*/
  // initializes cells in the link
  public void cell_initialization(){
    for(int i=0; i<num_cell; i++){
      cell_[i] = new Cell(Q_max);
    }

  }
  
  
  /*------------------------------------------------------------------------------------------------------------*/
  // update Q value if user wants to change
  public void Q_change(int Q_max_, int start_cell, int end_cell){
    for(int i=start_cell; i<end_cell; i++) cell_[i].Q = Q_max_;
  }
  
  
  /*------------------------------------------------------------------------------------------------------------*/
  public void calculate_yt(){
    for (int i=0; i<num_cell; i++){
      //cell_[i].y2 = 0; 
      int y1;
      if(i==0){
        if(random(100)<=volume/36) y1 = 1; //(volume/36) to convert to veh/ sec   
        else y1 = 0;
      }else y1 = cell_[i-1].n;
      
      cell_[i].y1 = min(y1, cell_[i].Q, cell_[i].N - cell_[i].n); // y_i(t) = min(y_i(t), Q_i(t), N_i(t) - n_i(t))
      cell_[i].y = cell_[i].y1;
    }
  }
  
  
  /*------------------------------------------------------------------------------------------------------------*/
  public void calculate_n(int end_cell_treatment){
    for(int i=0; i<num_cell-1; i++){
      cell_[i].nextn = cell_[i].n + cell_[i].y - cell_[i+1].y1; // here y1 is used to delete from same link; if I use y it will also consider other links input
    }
    if(end_cell_treatment==0) cell_[num_cell-1].nextn = 0; // it will clear vehicles from last cell
    else cell_[num_cell-1].nextn = cell_[num_cell-1].n + cell_[num_cell-1].y; // it will store vehicles in last cell. necessary in merging situation

    for(int i=0; i<num_cell; i++) cell_[i].n = cell_[i].nextn; // update n-> nextn
  }

}

/*========================================================================================================================================*/
  
  
void draw_simulation(Cell[] cell_, int num_cell, int x_pos, int y_pos, int shift_, int direction){
  
  for(int i=0; i<num_cell; i++){
    stroke(0);
    int color_factor = 255/N_max;
    fill((N_max - cell_[i].n)*color_factor); // instead of swtich. 
    
    /*------------------------------------------------------------------------------------------------------------*/
    if(direction==0) rect((i+1)*shift_+x_pos, y_pos,10, 10); // East bound
    else if(direction==1) rect((num_cell - i)*shift_+x_pos, y_pos,10, 10); // West bound
    else if(direction==2) rect(x_pos, (num_cell - i)*shift_+y_pos,10, 10); // North Bound
    else if(direction==3) rect(x_pos, (i+1)*shift_+y_pos,10, 10); // South bound
  }

}


/*========================================================================================================================================*/
