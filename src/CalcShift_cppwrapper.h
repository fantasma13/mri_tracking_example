#include <vector>

#ifndef _CALCULATESHIFT_WRAPPER_H
#define _CALCULATESHIFT_WRAPPER_H

#define CARDIACMOCO_ICE_NAMESPACE offline
#ifdef __cplusplus
//extern "C" {
#endif

std::vector<double> MyCalcShiftVector(std::vector<double> projections, std::vector<double> weights, std::vector<double> basis);
std::vector<double> MyCalcShiftFromFile(const char* filename, int size); // for MATLAB interface: argument must NOT be string




#ifdef __cplusplus
//}
#endif


#endif // 
