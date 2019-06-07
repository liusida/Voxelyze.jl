#voxelyze makefile

# This is the directory in which to find subdirectories to install/find headers and libs:
USER_HOME_PATH = $(HOME)

VOXELYZE_NAME = voxelyze
VOXELYZE_LIB_NAME = lib$(VOXELYZE_NAME)

CC=clang++
CXX=clang++
INCLUDE= -I./include
FLAGS = -O3 -std=c++14 -fPIC -Wall $(INCLUDE)

VOXELYZE_SRC = \
	src/Voxelyze.cpp \
	src/VX_Voxel.cpp \
	src/VX_External.cpp \
	src/VX_Link.cpp \
	src/VX_Material.cpp \
	src/VX_MaterialVoxel.cpp \
	src/VX_MaterialLink.cpp \
	src/VX_Collision.cpp \
	src/VX_LinearSolver.cpp \
	src/VX_MeshRender.cpp 

VOXELYZE_OBJS = \
	src/Voxelyze.o \
	src/VX_Voxel.o \
	src/VX_External.o \
	src/VX_Link.o \
	src/VX_Material.o \
	src/VX_MaterialVoxel.o \
	src/VX_MaterialLink.o \
	src/VX_Collision.o \
	src/VX_LinearSolver.o \
	src/VX_MeshRender.o
		
.PHONY: clean all

#dummy target that builds everything for the library
all: $(VOXELYZE_LIB_NAME).so $(VOXELYZE_LIB_NAME).a
	
# Auto sorts out dependencies (but leaves .d files):
%.o: %.cpp
#	@echo making $@ and dependencies for $< at the same time
	@$(CC) -c $(FLAGS) -o $@ $<
	@$(CC) -MM -MP $(FLAGS) $< -o $*.d

-include *.d

# Make shared dynamic library
$(VOXELYZE_LIB_NAME).so:	$(VOXELYZE_OBJS)
	$(CC) -shared $(INCLUDE) -o lib/$@ $^

# Make a static library
$(VOXELYZE_LIB_NAME).a:	$(VOXELYZE_OBJS)
	ar rcs lib/$(VOXELYZE_LIB_NAME).a $(VOXELYZE_OBJS)

clean:
	rm -rf *.o */*.o *.d */*.d lib/$(VOXELYZE_LIB_NAME).a lib/$(VOXELYZE_LIB_NAME).so

##################################################

$(USER_HOME_PATH)/include:
		mkdir $(USER_HOME_PATH)/include

$(USER_HOME_PATH)/lib:
		mkdir $(USER_HOME_PATH)/lib

installusr:     $(USER_HOME_PATH)/include $(USER_HOME_PATH)/lib
		cp lib/$(VOXELYZE_LIB_NAME) $(USER_HOME_PATH)/lib/$(VOXELYZE_LIB_NAME)
		rm -f $(USER_HOME_PATH)/lib/$(VOXELYZE_LIB_NAME)
		ln -s lib/$(VOXELYZE_LIB_NAME) $(USER_HOME_PATH)/lib/$(VOXELYZE_LIB_NAME)
		rm -rf $(USER_HOME_PATH)/include/$(VOXELYZE_NAME)
		-mkdir $(USER_HOME_PATH)/include/$(VOXELYZE_NAME)
		cp include/*.h $(USER_HOME_PATH)/include/$(VOXELYZE_NAME)
		-mkdir $(USER_HOME_PATH)/include/$(VOXELYZE_NAME)/rapidjson
		cp include/rapidjson/*.h $(USER_HOME_PATH)/include/$(VOXELYZE_NAME)/rapidjson
		rm -f $(USER_HOME_PATH)/include/$(VOXELYZE_NAME)
		ln -s $(VOXELYZE_NAME) $(USER_HOME_PATH)/include/$(VOXELYZE_NAME)

installglobal:
		cp lib/$(VOXELYZE_LIB_NAME) $(GLOBAL_PATH)/lib/$(VOXELYZE_LIB_NAME)
		rm -f $(GLOBAL_PATH)/lib/$(VOXELYZE_LIB_NAME)
		ln -s lib/$(VOXELYZE_LIB_NAME) $(GLOBAL_PATH)/lib/$(VOXELYZE_LIB_NAME)
		rm -rf $(GLOBAL_PATH)/include/$(VOXELYZE_NAME)
		-mkdir $(GLOBAL_PATH)/include/$(VOXELYZE_NAME)
		cp include/*.h $(GLOBAL_PATH)/include/$(VOXELYZE_NAME)
		-mkdir $(GLOBAL_PATH)/include/$(VOXELYZE_NAME)/rapidjson
		cp include/rapidjson/*.h $(GLOBAL_PATH)/include/$(VOXELYZE_NAME)/rapidjson
		rm -f $(GLOBAL_PATH)/include/$(VOXELYZE_NAME)
		ln -s $(VOXELYZE_NAME) $(GLOBAL_PATH)/include/$(VOXELYZE_NAME)