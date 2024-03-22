#include "CalcShift_cppwrapper.h"
#include "calculate_shift_vector.h"
#include <string>
#include <fstream>
#include <sstream>

using namespace std;

	std::vector<double> MyCalcShiftVector(std::vector<double> v_proj, std::vector<double> v_weights, std::vector<double> v_basis)
	{
		return CARDIACMOCO_ICE_NAMESPACE::CalcShiftVector(v_proj,v_weights,v_basis);
	}


std::vector<double> MyCalcShiftFromFile(const char * cfile, int size)
{

	std::string filename(cfile);
	//string filename("MOCOparam_-595_20220314_194928.log");
	std::vector<double> vvdReturn;


	bool bDebug = false;

	// read from file and test then

	std::ifstream myfile;
	// from: /ceph/mri.meduniwien.ac.at/projects/physics/met/data/Cardiac_31P/processing/C31P_MRS_moco-phantom-220314/physlog
	myfile.open(filename.c_str());

	if (!myfile.is_open()) {
#ifdef IS_NOT_MATLAB
		printf("file not open");
#endif
		return std::vector<double>();
	}

	string myline;
	int iStart = 9;

	int            iRep; 		// 0
	vector<double> vdTrans(3); 	// 2,3,4
	vector<double> vdRot(3);	// 5,6,7
	vector<int>    viID; 		//  8 + n*10
	vector<double> vdValue;		//  9 + n*10
	vector<double> vdWeight;	// 10 + n*10
	vector<double> vdStatus;	// 11 + n*10
	vector<double> vdSpacing;	// 12 + n*10
	vector<double> vdBasis;		// 13 + n*10
	char tmp[50];
	vector<double> vdReference;
	vector<double> vdVoxMot(3,0);
	vector<double> vdValueRef;
	vector<double> vdProjectionDiff;
	double         allErr = 0;


	while (getline(myfile,myline)) {
		// reset all vectors
		iRep = 0;
		vdTrans.clear();
		vdRot.clear();
		viID.clear();
		vdValue.clear();
		vdWeight.clear();
		vdStatus.clear();
		vdSpacing.clear();
		vdBasis.clear();
		vdProjectionDiff.clear();


		if (bDebug) {
#ifdef IS_NOT_MATLAB
			cout << "line is:\n\t" << myline.c_str() << endl;
#endif
		}

		if (myline.empty()) {
			if (bDebug) {
#ifdef IS_NOT_MATLAB
				printf("skip line (empty)\n");
#endif
			}
			continue;
		}
		if (myline.substr(0,1).compare("#") == 0) {
			if (bDebug) {
#ifdef IS_NOT_MATLAB
				printf("skip line (comment)\n");
#endif
			}
			continue;
		}
	


		// skip first part
		stringstream ss(myline);
		string word;
		vector<string> allwords;
		int cnt = -1, ccnt=0;
		vector<string> firstpart;
		bool bSkipRest = false;
		while (ss >> word) {
			if (bSkipRest) continue;

			cnt++;
			ccnt = cnt - 8;

			//cout << " word: " << word << endl;
			
			if (cnt < 8) {
				firstpart.push_back(word);
				switch (cnt) {
					case 0:
						iRep = stoi(word);
						break;
					case 2:
					case 3:
					case 4:
						vdVoxMot.at(cnt-2) = stod(word);
						break;
					default:
						break;
				}
				continue;
			}


			switch ( ccnt % 10 ) { 
				case 0:
					if (word.substr(0,1).compare("*") == 0) {
						bSkipRest = true;
#ifdef IS_NOT_MATLAB
						cout << "\n\n\n ABORT while \n\n\n" << endl;
#endif
						continue;
					}
					viID.push_back(stoi(word));
					break;
				case 1:
					vdValue.push_back(stod(word));
					break;
				case 2:
					vdWeight.push_back(stod(word));
					break;
				case 3:
					vdStatus.push_back(stod(word));
					break;
				case 4:
					vdSpacing.push_back(stod(word));
					break;
				case 6:
				case 7:
				case 8:
					vdBasis.push_back(stod(word));
					break;
				default:
					// do nothing
					//cout << "skipping   " << word.c_str() << endl;
					break;
			}
			allwords.push_back(word);
//			cout << '\t' << word << '\n';

		}

#ifdef IS_NOT_MATLAB
		cout << "rep #" << setw(3) << iRep << endl;
#endif


		if (vdValue.size() != vdSpacing.size()) {
#ifdef IS_NOT_MATLAB
			cout << "ERROR. incompatible sizes, should not happen..." << endl;
#endif
			return std::vector<double>();
		}
		if (vdValueRef.empty()) {
			vdValueRef = vdValue;
		}
		vector<double> vdProjection(vdValue.size());
		vdProjectionDiff.resize(vdValue.size());
		for (int i=0; i<vdValue.size(); ++i) {
			vdProjection.at(i) = vdValue[i]*vdSpacing[i];
			vdProjectionDiff.at(i)  = (vdValue[i] - vdValueRef[i])*vdSpacing[i];
		}
	

#ifdef IS_NOT_MATLAB
		if (bDebug) {
			cout << endl;
			cout << "\nfirstpart \n";
			for (auto element : firstpart) {
				cout << element << " ";
			}
			cout << endl;

			cout << "\nviID:\n";
			for (auto element : viID) {
				cout << element << " ";
			}
			cout << endl;

			cout << "\nvdValue:\n";
			for (auto element : vdValue) {
				cout << element << " ";
			}
			cout << endl;

			cout << "\nvdSpacing:\n";
			for (auto element : vdSpacing) {
				cout << element << " ";
			}
			cout << endl;

			cout << "\nvdWeights:\n";
			for (auto element : vdWeight) {
				cout << element << " ";
			}
			cout << endl;

			cout << "\nvdBasis:\n";
			for (auto element : vdBasis) {
				cout << element << " ";
			}
			cout << endl;

			cout << "\nvdProjection:\n";
			for (auto element : vdProjection) {
				cout << element << " ";
			}
			cout << endl;
		}
#endif

		// test CalcShiftVector
		std::vector<double> vdRes     = CARDIACMOCO_ICE_NAMESPACE::CalcShiftVector(vdProjection,vdWeight,vdBasis);
		std::vector<double> vdResDiff = CARDIACMOCO_ICE_NAMESPACE::CalcShiftVector(vdProjectionDiff,vdWeight,vdBasis);

		vvdReturn.insert( vvdReturn.end(), vdRes.begin(), vdRes.end() );

#ifdef IS_NOT_MATLAB
		if (bDebug) {
			cout << "\n\tvdRes:\t";
			for (auto element : vdRes) {
				cout << element << " ";
			}
			cout << endl;
		}
#endif

		if (vdReference.empty()) {
			vdReference = vdRes;
		}

		vector<double> vdMotion(3);
		for (int i=0; i<vdRes.size(); ++i) {
			vdMotion.at(i) = vdRes[i] - vdReference[i];
		}

		// quick-fix for this dataset: coordinate hacking...
		vector<double> vdCoordTrans{1,-1,-1};
		vector<double> vdErr(3);
		vector<double> vdErr1(3);
		for (int i=0; i<vdMotion.size(); ++i) {
			vdVoxMot.at(i) = vdVoxMot.at(i) * vdCoordTrans.at(i);
			vdErr.at(i)  = round(vdMotion[i] * 100.0)/100.0 - round(vdVoxMot[i]*100.0)/100.0;
			vdErr1.at(i) = round(vdMotion[i] * 100.0)/100.0 - round(vdResDiff[i]*100.0)/100.0;
		}

		if (true || bDebug) {
			double sumErr = 0;

#ifdef IS_NOT_MATLAB
			cout.precision(2);
			cout.setf(ios::fixed, ios::floatfield);

			cout << "\n\tvdResDiff:\t";
			for (auto element : vdResDiff) {
				cout << "\t" << element;
			}
			//cout << endl;
			
			cout << "\n\tvdMotion:\t";
			for (auto element : vdMotion) {
				cout << "\t" << element;
			}
#endif
			//cout << endl;
			for (auto element : vdErr1) {
				//cout << "\t" << element;
				sumErr+=element*element;
			}
			sumErr = sqrt(sumErr);
			allErr+=sumErr;
#ifdef IS_NOT_MATLAB
			cout << "\t" << sumErr;
		
			cout << "\n\tvdVoxMot:\t";
			for (auto element : vdVoxMot) {
				cout << "\t" << element;
			}
			//cout << endl;
#endif

			sumErr = 0;
			//cout << "\nvdErr:\t\t";
			for (auto element : vdErr) {
				//cout << "\t" << element;
				sumErr+=element*element;
			}
			sumErr = sqrt(sumErr);
#ifdef IS_NOT_MATLAB
			cout << "\t" << sumErr << endl;
			cout << endl;
#endif
		}

		

/////////////////////////////////
/// DEBUG: break after first iteration
//		break;

	}

#ifdef IS_NOT_MATLAB
	cout << "\n\nOVERALL ERROR: \t " << allErr << endl;

	cout << "\nfile used was: \t" << filename.c_str() << endl;
#endif


	myfile.close();


#ifdef IS_NOT_MATLAB
	printf("\nEND.\n");
#endif

	return vvdReturn;
}
