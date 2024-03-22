#include<vector>
#include<math.h>
#include<stdio.h>
#include<stdlib.h>
// to test outside ICE
#ifdef compile_offline
#define CARDIACMOCO_ICE_NAMESPACE offline
#define N_DIMS 3
#else
#include "CardiacFeedbackData.h"
#endif

// for regularisation in singular matrix
#define reg_threshold 0.05
namespace CARDIACMOCO_ICE_NAMESPACE {

//void calcShift(double vectors[][3], unsigned short i_vecsCount);
bool VecParCheck(std::vector <double> d_vecA, std::vector<double> d_vecB, double e);
double VecLen(std::vector<double> & d_vec);
double ScalarProjection(std::vector<double> vecA, std::vector<double> vecB);
double normDotProduct(std::vector<double> d_vecA, std::vector<double> d_vecB);
double DotProduct(std::vector<double> d_vecA, std::vector<double> d_vecB);

//std::vector<double> CalcShiftVector(std::vector<CardiacFBData> & FBData) ;
//std::vector<double> CalcShiftVector(double** std::vectors, unsigned short vecCount, std::vector<double> weights);
//std::vector<double> CalcShiftVector(std::vector<double> inputVecs, std::vector<double> weights);
// std::vector<double> TitoCalcShiftVector(std::vector<double> d_vecs, std::vector<double> weights);
std::vector<double> CalcShiftVector(std::vector<double> d_vecs, std::vector<double> weights, std::vector<double> basis);
#ifndef compile_offline
std::vector<double> CalcShiftVector(std::vector<CardiacFBData> FBData); //,std::vector<double> weights);
//std::vector<double> CalcShiftVector(std::vector<double> std::vectors, unsigned short vecCount, std::vector<double> weights);
std::vector<double> CalcShiftVector(std::vector<double> inputVecs, std::vector<double> weights);
//std::vector<double> calcShift(std::vector<double> inputVecs);
#endif
//
}
