#!/usr/bin/env bash

ARTIFACT=spring-petclinic-jpa
MAINCLASS=org.springframework.samples.petclinic.PetClinicApplication
VERSION=2.1.0.BUILD-SNAPSHOT
FEATURE=../../../../spring-graal-native-feature/target/spring-graal-native-feature-0.6.0.BUILD-SNAPSHOT.jar

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

rm -rf target
mkdir -p target/native-image

echo "Packaging $ARTIFACT with Maven"
../../mvnw -DskipTests package > target/native-image/output.txt

JAR="$ARTIFACT-$VERSION.jar"
rm -f $ARTIFACT
echo "Unpacking $JAR"
cd target/native-image
jar -xvf ../$JAR >/dev/null 2>&1
cp -R META-INF BOOT-INF/classes

LIBPATH=`find BOOT-INF/lib | tr '\n' ':'`
CP=BOOT-INF/classes:$LIBPATH:$FEATURE

GRAALVM_VERSION=`native-image --version`
echo "Compiling $ARTIFACT with $GRAALVM_VERSION"
time native-image \
  --no-server \
  --no-fallback \
  -DavoidLogback=true \
  -Ddebug=true \
  -Dio.netty.noUnsafe=true \
  -H:Name=$ARTIFACT \
  -H:+ReportExceptionStackTraces \
  --allow-incomplete-classpath \
  -H:+TraceClassInitialization \
  --report-unsupported-elements-at-runtime \
  --initialize-at-build-time=org.springframework.boot.validation.MessageInterpolatorFactory,org.hsqldb.jdbc.JDBCDriver,com.mysql.cj.jdbc.Driver,org.springframework.samples.petclinic.owner.PetRepository,org.springframework.samples.petclinic.owner.OwnerRepository,org.springframework.samples.petclinic.visit.VisitRepository,org.springframework.samples.petclinic.vet.VetRepository,org.springframework.samples.petclinic.owner.Pet,org.springframework.samples.petclinic.owner.Owner,org.springframework.samples.petclinic.model.NamedEntity,org.springframework.samples.petclinic.model.Person,org.springframework.samples.petclinic.model.BaseEntity,org.springframework.samples.petclinic.model.NamedEntity,org.springframework.samples.petclinic.visit.Visit,org.springframework.samples.petclinic.vet.Vet \
  -cp $CP $MAINCLASS >> output.txt

if [[ -f $ARTIFACT ]]
then
  printf "${GREEN}SUCCESS${NC}\n"
  mv ./$ARTIFACT ..
  exit 0
else
  printf "${RED}FAILURE${NC}: an error occurred when compiling the native-image.\n"
  exit 1
fi

