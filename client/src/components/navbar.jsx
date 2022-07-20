import React, { Component } from "react";

export default class Navbar extends Component {
  render() {
    return (
      <div className="navbar">
        <img src={process.env.PUBLIC_URL + '/Dazzle-logos_white.png'} alt="Logo" />
      </div>
    );
  }
}

