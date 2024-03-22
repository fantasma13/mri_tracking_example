#include <stdio.h>
#include <iostream>
#include <cmath>
#include <vector>
#include <stdexcept>	// std::runtime_error, throw
//#include "Gauss.h"
#include "calculate_shift_vector.h"
// from http://svn.lirec.eu
#include "SVD.h"
using namespace std;
#ifdef compile_offline
#define DICE_OUT(a) 

#endif
using namespace CARDIACMOCO_ICE_NAMESPACE;
//#endif

// TODO: change arrays to vectors
// TODO: cause error when insufficient linear independent vectors are found


  ///////////////////////////////////////////////////////////////////////////////
  //                                                                           //
  //                              support functions                            //
  //                                                                           //
  ///////////////////////////////////////////////////////////////////////////////

  // checks if two input vectors (2 1d arrays of length 3) are parallel - instead of return value 0, threshold e is introduced
  bool CARDIACMOCO_ICE_NAMESPACE::VecParCheck(vector<double> d_vecA, vector<double> d_vecB, double e)
  {

	  vector<double> d_norVec(3,0); //normal vector to vecA and vecB

    // dirty: replace later with function returning cross product
    //d_norVec = CrossProduct(d_vecA,d_vecB);

    d_norVec[0] = d_vecA[1]*d_vecB[2]-d_vecA[2]*d_vecB[1];
    d_norVec[1] = d_vecA[2]*d_vecB[0]-d_vecA[0]*d_vecB[2];
    d_norVec[2] = d_vecA[0]*d_vecB[1]-d_vecA[1]*d_vecB[0];

    double d_norVecLen = VecLen(d_norVec);
    bool b_vecParCheck = false;

    if (abs(d_norVecLen) < e )// numeric tolerance
    //if (d_norVecLen == 0) // if vectors parallel => cross product yields zero vector with lenght zero
    {
      b_vecParCheck = true;
    }
    return b_vecParCheck;
  }

  // calculates length of vector (1d input array of length 3);
  double CARDIACMOCO_ICE_NAMESPACE::VecLen(vector<double> & d_vec)
  {
    int i ;
    double d_len =0;
    for (i=0; i<(int)d_vec.size(); i++) {
    	d_len += d_vec[i]*d_vec[i];
    }
    // =(d_vec[0]*d_vec[0]+d_vec[1]*d_vec[1]+d_vec[2]*d_vec[2]);
    //d_len = sqrt(d_len);
    return d_len; //sqrt(d_len);
    
  }

  double CARDIACMOCO_ICE_NAMESPACE::normDotProduct(vector<double> d_vecA, vector<double> d_vecB)
  {
    double d_res = d_vecA[0]*d_vecB[0]+d_vecA[1]*d_vecB[1]+d_vecA[2]*d_vecB[2];
    double dL = VecLen(d_vecA);
    d_res = d_res / VecLen(d_vecA)/VecLen(d_vecB);
    return d_res;
  }

  double CARDIACMOCO_ICE_NAMESPACE::DotProduct(vector<double> d_vecA, vector<double> d_vecB)
  {
    double d_res = d_vecA[0]*d_vecB[0]+d_vecA[1]*d_vecB[1]+d_vecA[2]*d_vecB[2];
    return d_res;
  }

  double CARDIACMOCO_ICE_NAMESPACE::ScalarProjection(vector<double> vecA, vector<double> vecB)
  {

    //dirty: integrate something like below later
    //double d_vecBNorm = VecNorm(d_vecB);
    double d_len = VecLen(vecB);
    vector<double> d_vecBNorm(3,0); //[3] = {0, 0, 0};
    d_vecBNorm[0] = vecB[0]/d_len;
    d_vecBNorm[1] = vecB[1]/d_len;
    d_vecBNorm[2] = vecB[2]/d_len;
    double d_scalProjection = DotProduct(vecA, d_vecBNorm);
    return d_scalProjection;
  }


   
   //'void CARDIACMOCO_ICE_NAMESPACE::calcShift(vector<double> inputVectors, vector<double> weights, unsigned short i_vecsCount)
   void calcShift(vector<double> inputVectors, vector<double> weights, unsigned short i_vecsCount)
   {
  //   for (int i = 0; i < 4; i++)
  //   {
  //     for (int j = 0; j < 3; j++)
  //     {
  //       cout << inputVectors[i][j] << "\n\n\n";
  //     }
  //     //cout << "hello";
  //     //return 0;
  //   }


  ///////////////////////////////////////////////////////////////////////////////
  //                                                                           //
  //                   Find 3 linear independent vectors                       //
  //                                                                           //
  ///////////////////////////////////////////////////////////////////////////////


  //how many input vectors are there

  //cout << sizeof(inputVectors);

  if (inputVectors.size()/3 != i_vecsCount) {

	#ifndef compile_offline
  	ICE_ERR("Wrong number of inputs!"<< i_vecsCount);
	#endif
  }
  //very dirty - should derive amount of input vectors by default but does not work - I have given up for now, maybe replace with vector later
  int i_vecsCoun = inputVectors.size()/3;   // / sizeof(inputVectors[0]);
  //cout << i_vecsCoun << " :number of input vectors\n";

  // first index eg: array[a][b] -> this a
  //int i_cols = sizeof d_data[0] / sizeof(double); // second index eg: array[a][b] -> this b
  //empty array to host linear independent vectors
  vector<double> d_vecsLinInd(3*3,0); //[3][3] = {0, 0, 0, 0, 0, 0, 0, 0, 0}; //lineare independent vectors
  vector<double> d_vcur(3,0);
  int i_vecsLinIndCount = 0; //

  for (int i_indVec = 0; i_indVec < i_vecsCoun; i_indVec++)
  {

    cout << i_indVec  << " :i_indVec index here\n";

    vector<double> d_vec(3,0); //[3] = {0, 0, 0}; // => maybe make this a vector?

    // dirty: find better way to get subarray
    d_vec[0] = inputVectors[i_indVec*3+0];
    d_vec[1] = inputVectors[i_indVec*3+1];
    d_vec[2] = inputVectors[i_indVec*3+2];

    // init variable to check if vector is parallel


    for (int i_indParCheck = 0; i_indParCheck < i_indVec+1; i_indParCheck++)
    {
      bool b_par = true;
      cout << i_indParCheck << " :i_indParCheck index is here\n";
      // first vector is used as base vector by default
      if (i_indVec == 0)
      {
        cout << "first vector\n";
        i_vecsLinIndCount++;
        // maybe dirty: better way to maybe pass all 3 values at once would be nice
        d_vecsLinInd[0] = inputVectors[i_indVec*3+0];
        d_vecsLinInd[1] = inputVectors[i_indVec*3+1];
        d_vecsLinInd[2] = inputVectors[i_indVec*3+2];
      }
      else
      {
        cout << "other vector\n";
        double threshold = 0.0001; // threshold when vectors are parallel
	d_vcur[0]=inputVectors[i_indParCheck*3+0];
	d_vcur[1]=inputVectors[i_indParCheck*3+1];
	d_vcur[2]=inputVectors[i_indParCheck*3+2];

        b_par = VecParCheck(d_vec, d_vcur, threshold);
      }
      cout << b_par << " :par check value\n";
      //if vector with index indVec is parallel to vector with indParCheck -> stop and go to check next vector
      if (b_par == true)
      {
        cout << "par check true\n";
        break;
      }
      // if vector has been checked against all previous vectors of inputVectors -> add to vectors for GramSchmid
      else if (b_par == false && i_indParCheck == i_indVec - 1)
      {
        cout << "par check false\n";
        //Danger - wrong on purpose for now: fixed index 1 used - needs to be dynamic always suing next free index until 3 vectors found (maybe use i_vecsLinIndCount for this)
        d_vecsLinInd[i_vecsLinIndCount*3+0] = inputVectors[i_indVec*3+0];
        d_vecsLinInd[i_vecsLinIndCount*3+1] = inputVectors[i_indVec*3+1];
        d_vecsLinInd[i_vecsLinIndCount*3+2] = inputVectors[i_indVec*3+2];
        i_vecsLinIndCount++;
      }
    }
    if (i_vecsLinIndCount == 3)
    { cout << "all needed vectors found\n";
      break;
    }
  }

  cout << i_vecsLinIndCount << "lin indep vecs found!\n";

    for (int i = 0; i < 9; i++)
    {
      //for (int j = 0; j < 3; j++)
      //{
        cout << d_vecsLinInd[i] << "/";
      //}
       if ( i % 3==0 ) cout << "\n";
      //cout << "hello";
      //return 0;
    }
    cout << "\n";


    ///////////////////////////////////////////////////////////////////////////////
    //                                                                           //
    //                          make orthonormal base                            //
    //                                                                           //
    ///////////////////////////////////////////////////////////////////////////////

    // continue only if 3 vectors are found - needs to be implemented

    vector<double> d_vecsGS (3*3,0); //[3][3] = {0, 0, 0, 0, 0, 0, 0, 0, 0};

   for (int ii = 0; ii < 9; ii++)
    {
      //for (int jj = 0; jj < 3; jj++)
      //{
        d_vecsGS[ii] = d_vecsLinInd[ii];
      //}
    }

//int i_vecsCount = sizeof d_vecsLinInd / sizeof d_vecsLinInd[0]; // first index eg: array[a][b] -> this a

    int i_indi, i_indj, i_indk;

    // indi is index of vectors to be orthogonalized -> first vector stays untouched, index starts at second vector
      for(i_indi=1; i_indi<3; ++i_indi)
      {
        cout << "calc weights for vector: " << i_indi << "\n";
        double d_scalingFactor = 0;
	vector<double> d_vcur2(3,0);
	// TODO could be +3 / +6
	d_vcur2[0]=d_vecsLinInd[i_indj];
	d_vcur2[1]=d_vecsLinInd[i_indj+1];
	d_vcur2[2]=d_vecsLinInd[i_indj+2];
	// TODO could be +3 / +6
	d_vcur[0]=d_vecsGS[i_indj];
	d_vcur[1]=d_vecsGS[i_indj+1];
	d_vcur[2]=d_vecsGS[i_indj+2];
          for(int i_indj=0; i_indj<i_indi; i_indj++)
          {

	      // I dont undersand, the denominator is 1!
              //d_scalingFactor = DotProduct(d_vecsGS[i_indj], d_vecsLinInd[i_indi])
                                      /// DotProduct(d_vecsGS[i_indj], d_vecsGS[i_indj]);
              d_scalingFactor = DotProduct(d_vcur, d_vcur2) /
                                       DotProduct(d_vcur, d_vcur);
              cout << "calc weights with vector: " << i_indj << "\n";
              /* Subtract each scaled component of q_j from q_i 
	       * Tito, why do a third loop here? */
	      
              for(i_indk=0; i_indk<3; ++i_indk)
                  d_vecsGS[i_indi*3+i_indk] -= d_scalingFactor*d_vecsGS[i_indj*3+i_indk];
          }
      }

      for (i_indi = 0; i_indi < 3; i_indi++)
      {
       // TODO: maybe +3 / +6
	d_vcur[0]=d_vecsGS[i_indi+0];
	d_vcur[1]=d_vecsGS[i_indi+1];
	d_vcur[2]=d_vecsGS[i_indi+2];
        double d_len = VecLen(d_vcur);
        //for (int j = 0; j < 3; j++)
        //{
          d_vecsGS[i_indi*3+0] /= d_len;
          d_vecsGS[i_indi*3+1] /= d_len;
          d_vecsGS[i_indi*3+2] /= d_len;
          cout << d_vecsGS[i_indi] << "/";
        //}
	if ( i_indi % 3 == 0 ) cout << "\n";
        //return 0;
      }

      ///////////////////////////////////////////////////////////////////////////////
      //                                                                           //
      //                         calculate shift vector                            //
      //                                                                           //
      ///////////////////////////////////////////////////////////////////////////////

      //dummy error code -> needs to be replaced with array/ vector of error codes for each vector and corresponding action
      unsigned short errorCode = 0;
      double shiftThreshold = 0.0001;
      unsigned short shiftProjectionContributionCounter[3] = {0,0,0};

      //dummy base
      //double d_vecsGS[3][3]={{1,0,0},{0,1,0},{0,0,1}};

      // weight means: number to be multiplied to shift vector in d_vecs, set prior | ShiftWeights mean numbers needed to be multiplied to d_vecsGS (normed!) to get correct shift
      //int i_vecsCount = sizeof *d_vecs; // / sizeof d_vecs[0]; // first index eg: array[a][b] -> this a
      //cout << i_vecsCount << "this is vecsCount";

      /*double *weights = new double [i_vecsCount];
      for (int i_ind2 = 0; i_ind2 < i_vecsCount; i_ind2++)
      {
        weights[i_ind2] = 1;
      }
      */
      vector<double> d_vecShiftElems (3,0) ; //]={0,0,0}; // Weights which need to be applied to normed(!) d_vecsGS vectors like this: d_vecShiftWeights[0] to d_vecsGS[0][0-2],....
      unsigned short u_noError = 0; // default value if no error was found in error check of shift vector
      //unsigned short u_weightFactorIndex =
      for (int i_indV=0; i_indV<i_vecsCount; i_indV++) //i_indV index of shift vector to be investigated
      {
        if (errorCode == u_noError)
        {
          cout << "there is no error\n\n";
          vector<double> d_vec(3,0) ; //[3] = {0, 0, 0}; //get vector out of d_vecs with this variable and following loop
          for (int i_ind = 0; i_ind < 3; i_ind++)
          {
            d_vec[i_ind] = inputVectors[i_indV*3+i_ind];
          }
          for (int i_indB = 0; i_indB < 3; i_indB++) // iterate through all base vectors
          {
	    // TODO: check whether  + 3 / + 6
	    d_vcur[0]=d_vecsGS[ i_indB+0];
	    d_vcur[1]=d_vecsGS[ i_indB+1];
	    d_vcur[2]=d_vecsGS[ i_indB+2];
            double shiftProjection = ScalarProjection(d_vec, d_vcur)*weights[i_indV]; // calculate shift projection of shift vector d_vec on base vecter d_base with index i_indB multiplied by defineable weight
            if (shiftProjection > shiftThreshold)
            {
              d_vecShiftElems[i_indB] = (d_vecShiftElems[i_indB]*shiftProjectionContributionCounter[i_indB] + shiftProjection)/(shiftProjectionContributionCounter[i_indB]+1); //scalars needed to be applied to d_vecsGS (normed!)
              shiftProjectionContributionCounter[i_indB]++;
            }
          }
        }
      }

      for (int j = 0; j < 3; j++)
      {
        cout << d_vecShiftElems[j] << "/";
      }

}





///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                         single shift function                             //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////





std::vector<double> CARDIACMOCO_ICE_NAMESPACE::CalcShiftVector(vector<double> d_vecs, vector<double> weights, vector<double> basis)
{
	
	size_t m=d_vecs.size();
	int n=3;
	Matrix<float> A(m,n); 
	Matrix<float> Vec(n,n);
	//Matrix<float>ww(n,n);
	Matrix<float>b(m,1);
	vector<double> res(n,0);
	//if (basis.size() != n*m ) return 0;
	//if (weights.size() != m ) return 0;
	int i,j;
	float *w;
	w = new float [m];
	for (i = 0; i<m; i++) {
		for (j = 0; j<n; j++) {
			A[i][j]=basis[n*i+j]*weights[i];
			//cout <<"i "<<i<<", j "<<j<<", A(i,j), "<<A[i][j] <<"\n";
		}
		b[i][0]=weights[i]*d_vecs[i];
		//cout <<"i "<<i<<", w(i), "<<w[i] <<"\n";
	}
	int status = dsvd(A,m,n,w, Vec);
	// A now contains U
	//DICE_OUT("basis: \n"<<  A.Print());
	//DICE_OUT("projections: \n"<<  b.Print());
	// cout <<"b: \n";
	// b.Print();

	Matrix<float> c = A.Transposed()*b; //.Transposed();
	// c.Print();
	Matrix<float> y(1,n); // = ww*c.Transposed();
	//printf("1 / sigma; y: ( ");
	for (i = 0; i<n; i++) {
		//ww[i][i]=1/w[i]; // inverse
		// regularised case (https://www.mpp.mpg.de/~schieck/svd.pdf)
		// 1/s^2 -> s^2 /(s^2+t^2)^2
		if ( i>=m )  {
			y[0][i]=0;
		} else {
			float f = sqrt (w[i]*w[i]/(w[i]*w[i]+reg_threshold*reg_threshold)/(w[i]*w[i]+reg_threshold*reg_threshold));
			y[0][i]=c[i][0]*f;
		}
		//y[0][i]=((fabsf(w[i]))<1e-6F ? 0 : c[i][0]/w[i]);
		//printf ("%f; %f, ",1/w[i]),y[i][0];
	}
	
	//printf(")\n");
	//cout <<"y: \n" ;
	//y.Print();
	//cout <<"4.3\n";

	Matrix<float>x; //(n,1);
	x = Vec*y.Transposed();
	//cout <<"x: \n" ;
	//x.Print();
	for (i = 0; i<n; i++) {
		res[i]=x[i][0];
		//printf ("%f, ",res[i]);
	}
	//printf(")\n");
	return res;
}
/*
std::vector<double> TitoCalcShiftVector(vector<double> d_vecs, vector<double> weights)
{

  //dummy error code -> needs to be replaced with array/ vector of error codes for each vector and corresponding action
  unsigned short errorCode = 0;
  size_t i_vecsCount = d_vecs.size()/3;
  double shiftThreshold = 0.0001;
    unsigned short shiftProjectionContributionCounter[3] = {0,0,0};

  //dummy base
  vector<double > d_base(9,0); //[3][3]={{1,0,0},{0,1,0},{0,0,1}};

  // weight means: number to be multiplied to shift vector in d_vecs, set prior | ShiftWeights mean numbers needed to be multiplied to d_base (normed!) to get correct shift
  //int i_vecsCount = sizeof *d_vecs; // / sizeof d_vecs[0]; // first index eg: array[a][b] -> this a
  //cout << i_vecsCount << "this is vecsCount";

  
  vector<double> d_vecShiftElems(3,0); //[3]={0,0,0}; // Weights which need to be applied to normed(!) d_base vectors like this: d_vecShiftWeights[0] to d_base[0][0-2],....
  unsigned short u_noError = 0; // default value if no error was found in error check of shift vector
  //unsigned short u_weightFactorIndex =
  vector<double> sum(3,0);
  vector<double> sum_w(3,0);
  vector<double> d_vcur(3,0);

  for (int i_indV=0; i_indV<i_vecsCount; i_indV++) //i_indV index of shift vector to be investigated
  {
    if (errorCode == u_noError)
    {
      cout << "there is no error\n\n";
      vector<double> d_vec(3,0); //[3] = {0, 0, 0}; //get vector out of d_vecs with this variable and following loop
      for (int i_indB = 0; i_indB < 3; i_indB++) // iterate through all base vectors
      {
        d_vec[i_indB] = d_vecs[i_indV*3+i_indB];
      	//sum[i_indB]+=d_vec[i_indB]*weights[i_indV];
	// TODO: check this is not 3/6
	d_vcur[0]=d_base[i_indB+0];
	d_vcur[0]=d_base[i_indB+1];
	d_vcur[0]=d_base[i_indB+2];
        double shiftProjection = ScalarProjection(d_vec, d_vcur); // calculate shift projection of shift vector d_vec on base vecter d_base with index i_indB multiplied by defineable weight
	  double ww = normDotProduct(d_vec,d_vcur);
        if (shiftProjection > shiftThreshold)
        {
          d_vecShiftElems[i_indB] = (d_vecShiftElems[i_indB]*shiftProjectionContributionCounter[i_indB] + shiftProjection)/(shiftProjectionContributionCounter[i_indB]+1); //scalars needed to be applied to d_vecsGS (normed!)
          shiftProjectionContributionCounter[i_indB]++;
      	sum[i_indB]+=d_vec[i_indB]*weights[i_indV]*ww; ///shiftProjection
        sum_w[i_indB] += weights[i_indV]*ww;
        }
        //printf("ind %d sc.prod %f, vec %f; ",i_indB,ww,d_vec[i_indB]);
      }
      //printf("\nsum vector %f %f %f\n",sum[0],sum[1],sum[2]);
    }
  }
  
  // divide sum by the sum of the weights.
  for (int j = 0; j < 3; j++)
  {
    
    sum[j]/=sum_w[j];
    cout << d_vecShiftElems[j] << "/";
  }
  return sum;

  std::vector<double> resVec(3,-999);
  resVec[0] = d_vecShiftElems[0];
  resVec[1] = d_vecShiftElems[1];
  resVec[2] = d_vecShiftElems[2];
  return resVec;
}
*/	

// overloaded CalcShiftVector which accepts std::vector as input filled as: { v1_x, v1_y, v1_z, v2_x, v2_y, v2_z, v3_x, ...}
#ifndef compile_offline
std::vector<double> CARDIACMOCO_ICE_NAMESPACE::CalcShiftVector(std::vector<CardiacFBData> FBData) //, std::vector<double> weights) 
{
	unsigned short sLength = FBData.size(); // number of slices
	std::vector<double> basis; // 2 3D-vectors, 
	std::vector<double> data;  // 2 limits each (high/low)
	std::vector<double> weights;
	std::vector <double> res(N_DIMS,0);
	int ind=0,count=0,found = 0, unique_dirs=0;
	for (int slc = 0; slc < sLength; slc ++ ) {
		for (std::map<int,pos_t>::iterator it=FBData[slc].m_mFeatures.begin(); it!=FBData[slc].m_mFeatures.end(); ++it){
			pos_t pos =  it->second;
			if ( pos.weight < 0 ) {
				ICE_ERR("weights are < 0! (ind) " << ind << ", weights[ind] " << weights[ind]);
				throw std::runtime_error("weights are <0 ! Aborting...");
			}
			if ( pos.status || (pos.weight == 0) ) continue;
			basis.insert(basis.end(),pos.uvec.begin(), pos.uvec.end());
			data.insert(data.end(),pos.value*pos.spacing);
			weights.insert(weights.end(),pos.weight);
/*			bool test = false;
			for (int j=0; j<ind; j++) {
				if (std::inner_product(pos.uvec.begin(),pos.uvec.end(),basis.begin() + j,0.0) != 0) {
					test = true;
					break;
				}
			}
			ind++;
			if (test) count++;
*/
		}
	}

/*	if (count < 1) {
		ICE_WARN("CalcShift did not find any vectors to combine.");
		return res;
	} else if ( count == 1 ) {
		// TODO weighted sum
		//res=sum(weights*data*basis)/sum(weights);
		ICE_WARN("CalcShift: count = 1");
	} else if ( count == 2 ) {
		ICE_WARN("CalcShift: count = 2");
	} else {
		ICE_WARN("CalcShift: else-clause");
	}
*/

	res = CalcShiftVector(data,weights,basis);

	return res;
}

std::vector<double> CARDIACMOCO_ICE_NAMESPACE::CalcShiftVector(std::vector<double> inputVecs, std::vector<double> weights) 
{

	unsigned short i_vecsCount = static_cast<unsigned short>(inputVecs.size())/3;
	// dynamically allocate 2d-array
	short size_x = i_vecsCount;
	short size_y = 3;
	short itx, ity;

	std::vector<double> d_vecs (size_x,0); // = new double*[size_x];
	for(itx = 0; itx < size_x; itx++) {
		vector<double> tmp (3,0);
		tmp[0]=inputVecs[itx+0];
		tmp[1]=inputVecs[itx+1];
		tmp[2]=inputVecs[itx+2];
		d_vecs[itx] = VecLen(tmp);
	}
	
/*
	for(itx = 0; itx < size_x; itx++) {
		for(ity = 0; ity < size_y; ity++) {
			d_vecs[itx][ity] = inputVecs[3*itx + ity];
		}
	}
*/

	return CalcShiftVector(d_vecs,weights, inputVecs);
}

#endif
