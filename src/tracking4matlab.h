#ifndef TRACKING4MATLAB_H
#define TRACKING4MATLAB_H

#include<vector>

using namespace std;

//int videoTracking(int argc, char **argv);
int videoTracking();
int videoTracking(const char * cFilename);
int videoTracking(const char * cFilename, int iTracker);
int videoTracking(const char * cFilename, int iTracker, int iRefNum);
int videoTracking(const char * cFilename, int iTracker, int iRefNum, vector<int> viBbox);
int videoTracking(const char * cFilename, int iTracker, int iRefNum, vector<int> viBbox, bool bSilent);
int videoTracking(const char * cFilename, int iTracker, int iRefNum, vector<int> viBbox, bool bSilent, bool bSaveVid);

#endif
