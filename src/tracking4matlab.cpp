#include <opencv2/opencv.hpp>
#include <opencv2/video/tracking.hpp>
#include <opencv2/tracking/tracking.hpp>
#include <opencv2/core/ocl.hpp>
#include <numeric> 		// std::accumulate, std::inner_product, std::sqrt
#include <fstream>		// std::ofstream
 
using namespace cv;
using namespace std;

#define DEFAULT_TRACKER 2 // this is KCF
// Convert to string
#define SSTR( x ) static_cast< std::ostringstream & >( \
( std::ostringstream().seekp(0) << std::dec << x ) ).str()


Ptr<Tracker> create_tracker(string trackerType);
int runTracking(string sFilename, int iTracker, int iRefNum, vector<int> viBbox, bool bSilent, bool bSaveVid, bool bIsInit);

// overloads
int videoTracking(){
	std::string vidIn_name = "results/videos/157_flash_nav_set-210526_2slc_SETTER_START_slc-1.avi";		// arg[1]
	return runTracking(string(vidIn_name), DEFAULT_TRACKER, 0, vector<int>{20,30,40,50}, false, false, false);
};

int videoTracking(const char * cFilename){
	return runTracking(string(cFilename), DEFAULT_TRACKER, 0, vector<int>{20,30,40,50}, false, false, false);
};

int videoTracking(const char * cFilename, int iTracker){
	return runTracking(string(cFilename), iTracker, 0, vector<int>{20,30,40,50}, false, false, false);
};

int videoTracking(const char * cFilename, int iTracker, int iRefNum){
	return runTracking(string(cFilename), iTracker, iRefNum, vector<int>{20,30,40,50}, false, false, false);
};

int videoTracking(const char * cFilename, int iTracker, int iRefNum, vector<int> viBbox){
	return runTracking(string(cFilename), iTracker, iRefNum, viBbox, false, false, true);
};

int videoTracking(const char * cFilename, int iTracker, int iRefNum, vector<int> viBbox, bool bSilent){
	return runTracking(string(cFilename), iTracker, iRefNum, viBbox, bSilent, false, true);
};

int videoTracking(const char * cFilename, int iTracker, int iRefNum, vector<int> viBbox, bool bSilent, bool bSaveVid){
	return runTracking(string(cFilename), iTracker, iRefNum, viBbox, bSilent, bSaveVid, true);
};



// actual function
int runTracking(std::string sFilename, int trackerNumber, int initframe, vector<int> viBbox, bool bSilent, bool bSaveVid, bool bIsInit){

	string vidIn_name = string(sFilename);
	int x = viBbox[0];
	int y = viBbox[1];
	int w = viBbox[2];
	int h = viBbox[3];

	


	std::ofstream ofsLogfile;
	int cntFailures = 0;

    // List of tracker types in OpenCV 3.4.1/4.9.0
    string trackerTypes[11] = {"BOOSTING", "MIL", "KCF", "TLD","MEDIANFLOW", "GOTURN", "MOSSE", "CSRT", "DaSiamRPN", "Nano", "Vit" };

	// vector <string> trackerTypes(types, std::end(types));

	// Create a tracker
	string trackerType = trackerTypes[trackerNumber];
	if (!bSilent) {
		cout << "trackerType: " << trackerType << '\n';
	}

	
	Ptr<Tracker> tracker;

#if ((CV_MAJOR_VERSION == 3) && (CV_MINOR_VERSION < 3))
	{
		tracker = Tracker::create(trackerType);
	}
#else
	{
		tracker = create_tracker(trackerType);
		if (tracker == nullptr) {
			std::cout << "ERROR: wrong tracker selected, aborting..." << std::endl;
			return 99;
		}
	}
#endif

	// Read video
	if (!bSilent) {
		cout << "vidIn_name: " << vidIn_name << "\n"; 
	}
	VideoCapture vidIn;
	vidIn.open(vidIn_name);

	
	// Exit if video is not opened
	if(!vidIn.isOpened())
	{
		cout << "Could not read video file" << endl; 
		return 1; 
	} else {
		if (!bSilent) {
			cout << "Opening video successful." << endl;
		}
	}

	// Read first frame

	cv::Mat frame;
	bool ok;
	
	for (int idx=0; idx<=initframe; idx++) {
		ok = vidIn.read(frame); 
	}
	if (!bSilent) {
		std::cout << "channels " << frame.channels() << std::endl;
		std::cout << "cols " << frame.cols << std::endl;
		std::cout << "depth " << frame.depth() << std::endl;
		std::cout << "dims " << frame.dims << std::endl;
		std::cout << "empty " << frame.empty() << std::endl;
		std::cout << "flags " << frame.flags << std::endl;
		std::cout << "isContinuous " << frame.isContinuous() << std::endl;
		std::cout << "rows " << frame.rows << std::endl;
		std::cout << "size " << frame.size << std::endl;
		std::cout << "step " << frame.step << std::endl;
		std::cout << "total " << frame.total() << std::endl;
		std::cout << "type " << frame.type() << std::endl;
	}
	

	// Default resolution of the frame is obtained.The default resolution is system dependent. 
	int frame_width = vidIn.get(CAP_PROP_FRAME_WIDTH); 
	int frame_height = vidIn.get(CAP_PROP_FRAME_HEIGHT); 

	// Define initial bounding box 
	Rect bbox(x,y,w,h); 

	if (!bSilent) {
		cv::namedWindow("Tracking", WINDOW_NORMAL);
		cv::resizeWindow("Tracking", 4*frame_width, 4*frame_height);
	}

	// Select a different bounding box 
	if (!bIsInit) {
	
		bbox = selectROI(String("Tracking"), frame);
	}
	

	// Define the codec and create VideoWriter object.The output is stored in 'outcpp.avi' file. 
	std::string vidOut_name = vidIn_name;
	int extIndex = vidOut_name.find_last_of("/\\"); // find filename
	vidOut_name = vidOut_name.substr(extIndex+1); // filename.ext
	extIndex = vidOut_name.find_last_of("."); // find extension
	vidOut_name = vidOut_name.substr(0,extIndex); // filename w\o extension
	
	std::cout << "processing  " << vidOut_name.c_str() << ".avi" << std::flush;

	std::stringstream ssVidOut;
	ssVidOut << vidOut_name << "__TRACK_" << trackerNumber << "_" << bbox.x << "_" << bbox.y << "_" << bbox.width << "_" << bbox.height; 
	vidOut_name = ssVidOut.str() + ".avi";
	

	VideoWriter vidOut;
	if (bSaveVid) {
		vidOut.open(vidOut_name.c_str(),VideoWriter::fourcc('M','J','P','G'),10, Size(frame_width,frame_height));
	}

	// Open logfile
	
	ofsLogfile.open(ssVidOut.str() + ".log");
	ofsLogfile << "# video in:   " << vidIn_name.c_str() << "\n" << "# video out: " << vidOut_name.c_str() << "\n";
	ofsLogfile << "# tracker:    " << trackerNumber << " (" << trackerType.c_str() << ")\n";
	ofsLogfile << "# initframe:  " << initframe << "\n";
	ofsLogfile << "# initbbox:   " << bbox.x << " " << bbox.y << " " << bbox.width << " " << bbox.height << "\n";
	ofsLogfile << "\n";
	ofsLogfile << bbox.x << " " << bbox.y << " " << bbox.width << " " << bbox.height << "\n";


	// Display bounding box. 
	rectangle(frame, bbox, Scalar( 255, 0, 0 ), 2, 1 ); 
	

//	std::ostringstream ossbbox("");
//	ossbbox
//	ossbbox << bbox.x << " " << bbox.y << " " << bbox.width << " " << bbox.height << std::endl;
	
	if (!bSilent) {
		cv::imshow("Tracking", frame); 
	}

	tracker->init(frame, bbox);
	cntFailures=0;


	
	int iCounter=0;
	float fps_mean=0;
	std::vector<float> spf_list;
	std::vector<float> fps_list;

	while(vidIn.read(frame))
	{     
		// Start timer
		double timer = (double)getTickCount();

		// Update the tracking result
		bool ok = tracker->update(frame, bbox);

		// Calculate Frames per second (FPS)
		float fps = getTickFrequency() / ((double)getTickCount() - timer);
		fps_mean = (fps_mean*iCounter + fps)/++iCounter;
		spf_list.push_back( 1000./fps );
		fps_list.push_back(fps);

	


		if (ok)
		{
			// Tracking success : Draw the tracked object
			rectangle(frame, bbox, Scalar( 255, 0, 0 ), 2, 1 );

			// Log
			ofsLogfile << bbox.x << " " << bbox.y << " " << bbox.width << " " << bbox.height << "\n";
		}
		else
		{
			// Tracking failure detected.
			putText(frame, "Tracking failure detected", Point(100,80), FONT_HERSHEY_SIMPLEX, 0.1, Scalar(0,0,255),2);
			// Log
			ofsLogfile << "NAN NAN NAN NAN" << "\n";
			// Count tracking failures.
			cntFailures++;
		}

	
		// Display tracker type on frame
		//putText(frame, trackerType + " Tracker", Point(100,20), FONT_HERSHEY_SIMPLEX, 0.1, Scalar(50,170,50),2);

		// Display FPS on frame
		//putText(frame, "FPS : " + SSTR(int(fps)), Point(100,50), FONT_HERSHEY_SIMPLEX, 0.1, Scalar(50,170,50), 2);

		int k = 0;

		// Display frame.
		if (!bSilent) {
			imshow("Tracking", frame);
			cout << "\n" << "boundingbox (" << iCounter << "): " << bbox << "   at " << fps << " fps   (avg.: " << fps_mean << " fps)" << '\n';
			// Exit if ESC pressed.
			k = waitKey(1);
		}

		if(k == 27)
		{
			break;
		}

	
		if (bSaveVid) {
			vidOut.write(frame);
		}

	}

	// Calc timing info
	float ms_mean   = std::accumulate(spf_list.begin(), spf_list.end(),0.0)/spf_list.size();
	float ms_std    = std::sqrt(std::inner_product(spf_list.begin(), spf_list.end(), spf_list.begin(), 0.0) / spf_list.size() - ms_mean * ms_mean);
	fps_mean  = std::accumulate(fps_list.begin(), fps_list.end(),0.0)/fps_list.size();
	float fps_std   = std::sqrt(std::inner_product(fps_list.begin(), fps_list.end(), fps_list.begin(), 0.0) / fps_list.size() - fps_mean * fps_mean);

	


	// dump stuff to eof
	ofsLogfile << std::endl;
	ofsLogfile << "#failures := " << cntFailures << std::endl;
	ofsLogfile << "#fps mean/std := " << fps_mean << " \t" << fps_std << std::endl;
	ofsLogfile << "#spf mean/std := " << ms_mean << " \t" << ms_std << std::endl;




	vidOut.release();
	vidIn.release();
	ofsLogfile.close();

	//cv::destroyAllWindows();

	if (!bSilent && bSaveVid) {
		std::cout << "writing  " << vidOut_name.c_str() << std::flush;
	}


	

	
	std::cout << "  done. (" << cntFailures << " failures, " << fps_mean << " fps, " << ms_mean << " +- " << ms_std << " ms )" << std::endl; // << vidOut_name.c_str() << std::endl;


	return 0;
};

Ptr<Tracker> create_tracker(string trackerType)
{
        if (trackerType == "BOOSTING")
		return Ptr<Tracker>();
		//tracker = TrackerBoosting::create();
        if (trackerType == "MIL")
            	return TrackerMIL::create();
        if (trackerType == "KCF")
		return TrackerKCF::create();
        if (trackerType == "TLD")
		return Ptr<Tracker>();
      		//tracker = TrackerTLD::create();
        if (trackerType == "MEDIANFLOW")
		return Ptr<Tracker>();
            	//tracker = TrackerMedianFlow::create();
        if (trackerType == "GOTURN")
		return TrackerGOTURN::create();
	if (trackerType == "MOSSE")
		return Ptr<Tracker>();
		//tracker = TrackerMOSSE::create();
        if (trackerType == "CSRT")
		return TrackerCSRT::create();
	if (trackerType == "DaSiamRPN")
		return Ptr<Tracker>();
		//return TrackerDaSiamRPN::create();
	if (trackerType == "Nano")
		return Ptr<Tracker>();
		//return TrackerNano::create();
	if (trackerType == "Vit")
		return Ptr<Tracker>();
		//return TrackerVit::create();

	return Ptr<Tracker>();
};
