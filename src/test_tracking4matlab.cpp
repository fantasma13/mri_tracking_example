#include "tracking4matlab.h"
#include <fstream>
#include <iostream>

using namespace std;

#define DEFAULT_TRACKER 2 // this is KCF

inline int arrayTest(int argc, char **argv){return 0;};
int videoTest(int argc, char **argv);
inline int imageTest(int argc, char **argv){return 0;};


// 1 or 2 arguments; 1st: filename of video; 2nd: trackerNumber;
int main(int argc, char **argv)
{
	if (argc>1){
		int inChoice = atoi(argv[1]);
		switch (inChoice){
		case 1:
			return videoTest(argc-1,&argv[1]);
			break;
		case 2:
			return imageTest(argc-1,&argv[1]);
			break;
		case 3:
			return arrayTest(argc-1,&argv[1]);
			break;
		default:
			std::cout << "argv[1] = " << argv[1] << std::endl;
			std::cout << "no valid argument, aborting..." << std::endl;
			std::cout << "\tvalid arguments:" << std::endl;
			std::cout << "\t\t1: read video" << std::endl;
			std::cout << "\t\t2: read image(s)" << std::endl;
			std::cout << "\t\t3: read array(s)" << std::endl;
			return 1;
			break;
		};
	} else {
		std::cout << "too few input arguments, aborting..." << std::endl;
		std::cout << "hint:\n" << "\t" << argv[0] << " TYPE ARGUMENTS " << std::endl;
		std::cout << "\tTYPE: \n\t\t1: video\n\t\t2: image\n\t\t3: array" << std::endl;
		return 0;
	}
}



int videoTest(int argc, char **argv){
	// argv[0] is argc
	std::string vidIn_name = "c31p_mrs_20_3_76.avi";		// arg[1]
	int trackerNumber = DEFAULT_TRACKER;								// arg[2]
	int x = 53;											// arg[3]
	int y = 40;											// arg[4]
	int w = 30;											// arg[5]
	int h = 30;											// arg[6]
	bool bIsInit = false;
	int initframe = 0;
	bool bSilent = false;
	bool bSaveVid = true;
	std::ofstream ofsLogfile;
	int cntFailures = 0;

	// check number of input-arguments
	switch (argc) {
		case 10:
			bSaveVid=(bool)atoi(argv[9]);
		case 9:
			bSilent=(bool)atoi(argv[8]);

		case 8: 
			x=atoi(argv[4]);
			y=atoi(argv[5]);
			w=atoi(argv[6]);
			h=atoi(argv[7]);
			bIsInit = true;

		case 4:
			initframe=atoi(argv[3]);

		case 3: 
			trackerNumber = atoi(argv[2]);

		case 2: 
			vidIn_name = argv[1];
			break;
		case 1:
		default:
			//std::cout << "argv[0] = " << argv[0] << std::endl;
			std::cout << "use 2, 3, 4 or 8 arguments:" << std::endl;
			std::cout << "\t2: filename" << std::endl;
			std::cout << "\t3: tracker-number (default: " << DEFAULT_TRACKER << ")" << std::endl;
			std::cout << "\t4: repetition-number for initializing the tracker (default: 0)" << std::endl; 
			std::cout << "\t5-8: bounding-box as 'x y w h'  (default: " << x << " " << y << " " << w << " " << h << ")" << std::endl;
			std::cout << "\t9: run silently  0=false, 1=true (default: 0)" << std::endl;
			std::cout << "\t10: save video?  0=false, 1=true (default: 1)" << std::endl;
			return 99;
			break;
	}



	if (bIsInit) {
		std::vector<int> viBbox {x,y,w,h};
		return videoTracking(vidIn_name.c_str(),trackerNumber,initframe,viBbox,bSilent,bSaveVid);
	} else {
		return videoTracking(vidIn_name.c_str(),trackerNumber,initframe);
	}	

};


