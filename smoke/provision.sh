#!/bin/sh -e

if [ -z "$influx_version" ]; then
  echo "== Provisioning InfluxDB: Skipping, influx_version is empty"
  exit 0
else
  echo "== Provisioning InfluxDB ${influx_version}"
fi

package_name="influxdb_${influx_version}_amd64.deb"
[ -z "${channel}" ] && channel="releases"
download_url="https://dl.influxdata.com/influxdb/${channel}/${package_name}"


echo "== Downloading package"

if which curl 2>&1 >/dev/null; then
  curl "${download_url}" > "${HOME}/${package_name}"
else
  echo >&2 "E: Could not find curl"
  exit 1
fi

echo "== Download verification"
hash_sum=$(md5sum "${HOME}/${package_name}" | awk '{ print $1 }')

if [ -z "${pkghash}" ]; then
  echo "-- Skipping, pkghash is empty"
else
  if [ "${hash_sum}" != "${pkghash}" ]; then
    echo >&2 "E: Hash sum mismatch (got ${hash_sum}, expected ${pkghash})"
    exit 1
  fi
fi
echo "-- Download has MD5 hash: ${hash_sum}"


echo "== Installing"

sudo dpkg -i "${HOME}/${package_name}"
sudo /etc/init.d/influxdb start

echo "-- waiting for daemon to start"
while ! curl --head --fail --silent http://localhost:8086/ping; do
  echo -n "."
  sleep 1
done


echo "== Configuring"

echo "-- create admin user"
/usr/bin/influx -execute "CREATE USER root WITH PASSWORD 'toor' WITH ALL PRIVILEGES"

echo "-- create non-admin user"
/usr/bin/influx -execute "CREATE USER test_user WITH PASSWORD 'resu_tset'"

echo "-- create databases"
/usr/bin/influx -execute "CREATE DATABASE db_one"
/usr/bin/influx -execute "CREATE DATABASE db_two"

echo "-- grant access"
/usr/bin/influx -execute "GRANT ALL ON db_two TO test_user"


echo "== Download and import NOAA sample data"

curl https://s3-us-west-1.amazonaws.com/noaa.water.database.0.9/NOAA_data.txt > noaa.txt
/usr/bin/influx -import -path noaa.txt -precision s

echo "-- grant access"
/usr/bin/influx -execute "GRANT ALL ON NOAA_water_database TO test_user"


echo "== Enable authentication"

if [ ! -f /etc/influxdb/influxdb.conf ]; then
  echo >&2 "E: config file not found"
  exit 1
fi

sudo sed -i 's/auth-enabled = false/auth-enabled = true/' /etc/influxdb/influxdb.conf
sudo /etc/init.d/influxdb restart

echo "-- waiting for daemon to restart"
while ! curl --head --fail --silent http://localhost:8086/ping; do
  echo -n "."
  sleep 1
done


echo "== Done"
