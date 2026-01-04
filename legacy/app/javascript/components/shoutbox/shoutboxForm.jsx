import React from "react";

class ShoutboxForm extends React.Component {
    constructor(props) {
        super(props);
        this.state = {shout: ''};
        this.handleChange = this.handleChange.bind(this);
        this.handleSubmit = this.handleSubmit.bind(this);
    }

    handleChange(event) {
        this.setState({shout: event.target.value});
    }

    handleSubmit(event) {
        event.preventDefault();
        this.props.onShoutboxEntrySubmit(this.state.shout)
        this.setState({shout: ''});
    }

    renderForm() {
        return (
            <div className="new-post">
                <form onSubmit={this.handleSubmit}>
                    <input
                        type="text" value={this.state.shout}
                        onChange={this.handleChange}
                        maxLength="100"
                    />
                    <div className="shoutboxButton">
                        <input type="submit" value="Senden" disabled={this.props.postingNewEntry} className="button" />
                    </div>
                </form>
            </div>
        );
    }

    renderLoginLink() {
        return (
            <div className="login">
                Du musst dich <a href="/login">anmelden</a> um hier zu posten.
            </div>
        )
    }

    render() {
        if (this.props.loggedIn) {
            return this.renderForm();
        } else {
            return this.renderLoginLink();
        }
    }
}

export default ShoutboxForm;
