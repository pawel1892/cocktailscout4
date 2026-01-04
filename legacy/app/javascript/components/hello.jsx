import React from 'react'

export default class Hello extends React.Component {
    constructor(props) {
        super(props);
        this.state = {counter: 0};
        this.handleClick = this.handleClick.bind(this);
    }

    handleClick() {
        this.setState(prevState => ({
            counter: prevState.counter + 1
        }));
    }

    render() {
        return (
            <div>
                <div>Hallo {this.props.name}</div>
                <button type="button" className={'button'} onClick={this.handleClick}>Klick mich an!</button>
                <div>Du hast {this.state.counter} mal gedrückt.</div>
            </div>
        );
    }
}
