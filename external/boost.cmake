# -*- mode: cmake -*-

# Limit scope of the search if BOOST_ROOT or BOOST_INCLUDEDIR is provided.
if (BOOST_ROOT OR BOOST_INCLUDEDIR)
  set(Boost_NO_SYSTEM_PATHS TRUE)
endif()

# make sure Boost::boost is available, and look for optional serialization component
if (NOT TARGET Boost::boost OR NOT TARGET Boost::serialization)
  set(Boost_BTAS_DEPS_LIBRARIES serialization)
  # try config first
  # OPTIONAL_COMPONENTS in FindBoost available since 3.11
  cmake_minimum_required(VERSION 3.11.0)
  find_package(Boost CONFIG OPTIONAL_COMPONENTS ${Boost_BTAS_DEPS_LIBRARIES})
  if (NOT TARGET Boost::boost)
    find_package(Boost REQUIRED OPTIONAL_COMPONENTS ${Boost_BTAS_DEPS_LIBRARIES})
    set(Boost_USE_CONFIG FALSE)
  else()
    set(Boost_USE_CONFIG TRUE)
  endif()
endif (NOT TARGET Boost::boost OR NOT TARGET Boost::serialization)

# Perform a compile check with Boost
list(APPEND CMAKE_REQUIRED_INCLUDES ${Boost_INCLUDE_DIRS})
list(APPEND CMAKE_REQUIRED_LIBRARIES ${Boost_LIBRARIES})
target_compile_definitions(BTAS INTERFACE -DBTAS_HAS_BOOST_ITERATOR=1)
if (Boost_CONTAINER_FOUND)
  target_compile_definitions(BTAS INTERFACE -DBTAS_HAS_BOOST_CONTAINER=1 -DBTAS_TARGET_MAX_INDEX_RANK=${TARGET_MAX_INDEX_RANK})
endif()

set(_btas_boostcheck_source "
    #define BOOST_TEST_MAIN main_tester
    #include <boost/test/included/unit_test.hpp>

    #include <fstream>
    #include <cstdio>
    #include <boost/archive/text_oarchive.hpp>
    #include <boost/archive/text_iarchive.hpp>
    #ifdef BTAS_HAS_BOOST_CONTAINER
    #  include <boost/container/small_vector.hpp>
    #endif

    class A {
      public:
        A() : a_(0) {}
        A(int a) : a_(a) {}
        bool operator==(const A& other) const {
          return a_ == other.a_;
        }
      private:
        int a_;

        friend class boost::serialization::access;
        template<class Archive>
        void serialize(Archive & ar, const unsigned int version)
        {
          ar & a_;
        }
    };

    BOOST_AUTO_TEST_CASE( serialization )
    {
      BOOST_CHECK( true );

      A i(1);
      const char* fname = \"tmp.boost\";
      std::ofstream ofs(fname);
      {
        boost::archive::text_oarchive oa(ofs);
        oa << i;
      }
      {
        std::ifstream ifs(fname);
        boost::archive::text_iarchive ia(ifs);
        A i_restored;
        ia >> i_restored;
        BOOST_CHECK(i == i_restored);
        remove(fname);
      }
    }

    #ifdef BTAS_HAS_BOOST_CONTAINER
    BOOST_AUTO_TEST_CASE( container )
    {
      boost::container::small_vector<int, 1> v;
      BOOST_CHECK_NO_THROW(v.push_back(0));
      BOOST_CHECK_NO_THROW(v.push_back(1));
      BOOST_CHECK(v[0] == 0);
      BOOST_CHECK(v[1] == 1);
    }
    #endif  // BTAS_HAS_BOOST_CONTAINER
    ")
if (CMAKE_CROSSCOMPILING)
  include(CheckCXXSourceCompiles)
  check_cxx_source_compiles("${_btas_boostcheck_source}" BOOST_COMPILES_AND_RUNS)
else(CMAKE_CROSSCOMPILING)
  include(CheckCXXSourceRuns)
  check_cxx_source_runs("${_btas_boostcheck_source}" BOOST_COMPILES_AND_RUNS)
endif(CMAKE_CROSSCOMPILING)

if (BOOST_COMPILES_AND_RUNS)
    target_compile_definitions(BTAS INTERFACE -DBTAS_HAS_BOOST_SERIALIZATION=1)
else ()
  message(STATUS "Boost found at ${BOOST_ROOT}, but could not compile and/or run test program")
  message(WARNING "To obtain usable Boost, use your system package manager (HomeBrew, apt, etc.) OR download at www.boost.org and compile (unpacking alone is not enough)")
  message(WARNING "** !! due to missing Boost.Serialization the corresponding unit tests will be disabled !!")
endif(BOOST_COMPILES_AND_RUNS)

target_include_directories(BTAS INTERFACE ${Boost_INCLUDE_DIRS})
target_link_libraries(BTAS INTERFACE ${Boost_LIBRARIES})
