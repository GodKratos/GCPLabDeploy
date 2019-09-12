provider "google" {
  project = "${var.var_project}"
  region  = "${var.var_region}"
  zone    = "${var.var_zone}"
}
